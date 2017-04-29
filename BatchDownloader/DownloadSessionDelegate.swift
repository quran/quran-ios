//
//  DownloadSessionDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import VFoundation

class DownloadSessionDelegate: NSObject, URLSessionDownloadHandler {

    private let acceptableStatusCodes = 200..<300

    private let queue: OperationQueue
    private let persistence: DownloadsPersistence

    private var downloadingResponses: [Int: DownloadNetworkResponse] = [:]
    private var downloadBatches: [DownloadBatch] = []
    private var populated = false

    weak var cancellable: NetworkResponseCancellable?

    var backgroundSessionCompletionHandler: (() -> Void)?

    init(persistence: DownloadsPersistence, queue: OperationQueue) {
        self.persistence = persistence
        self.queue = queue
        super.init()
        queue.promise {
            self.downloadBatches = try persistence.retrieve(status: .downloading)
            }.cauterize(tag: "downloadSessionDelegate.retreiving.downloads")
    }

    private func response(for task: URLSessionTask) -> DownloadNetworkResponse? {
        if let response = downloadingResponses[task.taskIdentifier] {
            return response
        }

        let target = downloadBatches
            .flatMap { $0.downloads }
            .first { $0.taskId == task.taskIdentifier }
        guard let download = target else {
            return nil
        }
        let progress = QProgress(totalUnitCount: 1)
        let downloadRequest = DownloadNetworkResponse(task: task, download: download, progress: progress, cancellable: cancellable)
        downloadingResponses[task.taskIdentifier] = downloadRequest
        return downloadRequest
    }

    private func cleanUpDownloads() {
        let batches = downloadingResponses.map { $1 }.group { $0.download.batchId ?? 0 }
        for (batchId, batch) in batches {
            let isDownloading = batch.contains { $0.download.status == .downloading }
            // if all completed or failed or mix between both, remove the batch
            if !isDownloading {
                for item in batch {
                    let taskId = unwrap(item.download.taskId)
                    downloadingResponses[taskId] = nil
                }
                suppress {
                    try persistence.delete(batchId: batchId)
                }
            }
        }
    }

    func populateOnGoingDownloads(from downloadTasks: [URLSessionTask]) {
        populated = false

        // group tasks by id
        let tasksByIds: [Int: URLSessionTask] = downloadTasks.flatGroup { $0.taskIdentifier }

        // loop over the downloads
        let downloads = downloadBatches.flatMap { $0.downloads }
        for download in downloads {
            let taskId = unwrap(download.taskId)
            guard downloadingResponses[taskId] == nil else {
                continue
            }
            if let task = tasksByIds[taskId] {
                let progress = QProgress(totalUnitCount: 1)
                let downloadRequest = DownloadNetworkResponse(task: task, download: download, progress: progress, cancellable: cancellable)
                downloadingResponses[taskId] = downloadRequest
            } else {
                if download.status == .completed {
                    let progress = QProgress(totalUnitCount: 1)
                    progress.completedUnitCount = 1
                    let downloadRequest = DownloadNetworkResponse(task: nil, download: download, progress: progress, cancellable: cancellable)
                    downloadingResponses[taskId] = downloadRequest
                } else if download.status == .downloading {
                    // set it as failed
                    suppress {
                        try persistence.update(url: download.url, newStatus: .failed)
                    }
                }
            }
        }
        downloadBatches.removeAll()
        cleanUpDownloads()
        populated = true
    }

    func addOnGoingDownloads(_ downloads: [DownloadNetworkResponse]) {
        // create the onGoingDownloads once so we can use it before the persistence value is written.
        for download in downloads {
            let taskId = unwrap(download.download.taskId)
            downloadingResponses[taskId] = download
        }
        do {
            // update the status
            let downloadsToInsert = downloads.map { response -> Download in
                var d = response.download
                d.status = .downloading
                return d
            }
            // insert the batch
            let batch = try persistence.insert(batch: downloadsToInsert)

            // update the responses and the downloading
            for (index, response) in downloads.enumerated() {
                // update the download
                response.download = batch[index]
                // add it to downloading
                let taskId = unwrap(response.download.taskId)
                downloadingResponses[taskId] = response
            }
        } catch {
            Crash.recordError(error, reason: "addOnGoingDownloads")
            downloads.first?.result = .failure(error)
        }
    }

    func getOnGoingDownloads() -> [DownloadNetworkBatchResponse] {
        let groups = downloadingResponses.values.group { $0.download.batchId ?? 0 }
        return groups.map { DownloadNetworkBatchResponse(responses: $1) }
    }

    private func taskFailed(_ task: URLSessionTask) -> DownloadNetworkResponse? {
        return update(task: task, status: .failed)
    }

    private func taskCompleted(_ task: URLSessionTask) -> DownloadNetworkResponse? {
        return update(task: task, status: .completed)
    }

    private func update(task: URLSessionTask, status: Download.Status) -> DownloadNetworkResponse? {
        guard let downloadRequest = response(for: task) else {
            return nil
        }
        // we get only update the downloading
        guard downloadRequest.download.status == .downloading else {
            return downloadRequest
        }
        var download = downloadRequest.download
        download.status = status
        downloadRequest.download = download
        downloadingResponses[task.taskIdentifier] = downloadRequest

        suppress {
            try persistence.update(url: download.url, newStatus: status)
        }

        // delete the batch if all completed/failed
        if populated {
            cleanUpDownloads()
        }
        return downloadRequest
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let response = response(for: downloadTask) else {
            CLog("Cannot find onGoingDownloads for task with id \(downloadTask.taskIdentifier) - " +
                "URL(\(downloadTask.currentRequest?.url?.absoluteString ?? ""))")
            return
        }
        response.progress.totalUnitCount = Double(totalBytesExpectedToWrite)
        response.progress.completedUnitCount = Double(totalBytesWritten)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // validate task response
        guard validate(task: downloadTask) == nil else {
            return
        }

        guard let download = response(for: downloadTask)?.download else {
            CLog("Missed saving task", downloadTask.currentRequest?.url as Any)
            return
        }
        let fileManager = FileManager.default

        let resumeURL = FileManager.documentsURL.appendingPathComponent(download.resumePath)
        let destinationURL = FileManager.documentsURL.appendingPathComponent(download.destinationPath)

        // remove the resume data
        try? fileManager.removeItem(at: resumeURL)
        // remove the existing file if exist.
        try? fileManager.removeItem(at: destinationURL)

        // move the file to destination
        do {
            let directory = destinationURL.deletingLastPathComponent()
            try? fileManager.createDirectory(at: directory,
                                             withIntermediateDirectories: true,
                                             attributes: nil)
            try fileManager.moveItem(at: location, to: destinationURL)

        } catch {
            Crash.recordError(error, reason: "Problem with create directory or copying item to the new location '\(destinationURL)'",
                fatalErrorOnDebug: false)
            // early exist with error
            let downloadRequest = taskFailed(downloadTask)
            downloadRequest?.result = .failure(FileSystemError(error: error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError sessionError: Error?) {

        let validationError = validate(task: task)
        let theError = sessionError ?? validationError

        // remove the request
        let networkResponse: DownloadNetworkResponse?
        if theError != nil {
            networkResponse = taskFailed(task)
        } else {
            networkResponse = taskCompleted(task)
        }
        guard let response = networkResponse else {
            return
        }

        // if success, early return
        guard var error = theError else {
            response.result = .success()
            return
        }

        // save resume data, if found
        if let resumeData = error.resumeData {
            let resumeURL = FileManager.documentsURL.appendingPathComponent(response.download.resumePath)
            suppress {
                try resumeData.write(to: resumeURL, options: [.atomic])
            }
            error = error.removeResumeData()
        }

        // not cancelled by user
        guard !error.isCancelled else {
            return
        }

        Crash.recordError(error, reason: "Download network error occurred")

        let finalError: Error
        if error is POSIXErrorCode && Int32((error as NSError).code) == ENOENT {
            finalError = FileSystemError.noDiskSpace
        } else {
            finalError = NetworkError(error: error)
        }
        response.result = .failure(finalError)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let handler = backgroundSessionCompletionHandler
        backgroundSessionCompletionHandler = nil
        handler?()
    }

    func cancel(_ response: DownloadNetworkResponse) {
        queue.promise { [weak self] in
            guard let `self` = self else { return }

            let batchId = unwrap(response.download.batchId)
            let batch: [DownloadNetworkResponse] = self.downloadingResponses
                .map { $1 }
                .filter { $0.download.batchId == batchId }

            // remove from memory
            for item in batch {
                let taskId = unwrap(item.download.taskId)
                self.downloadingResponses[taskId] = nil
            }

            guard !batch.isEmpty else {
                // we already cancelled it before
                return
            }

            // cancel all tasks
            for response in batch {
                response.task?.cancel()
            }

            // remove from persistence
            suppress {
                try self.persistence.delete(batchId: batchId)
            }
            }.cauterize()
    }

    private func validate(task: URLSessionTask) -> Error? {
        let httpResponse = task.response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        if !acceptableStatusCodes.contains(statusCode) {
            return NetworkError.serverError("Unacceptable status code: \(statusCode)")
        } else {
            return nil
        }
    }
}

extension Error {
    fileprivate var resumeData: Data? {
        return (self as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    }

    fileprivate var isCancelled: Bool {
        return (self as? URLError)?.code == URLError.cancelled
    }

    fileprivate func removeResumeData() -> Error {
        let error = self as NSError
        guard error.userInfo[NSURLSessionDownloadTaskResumeData] != nil else {
            return self
        }
        var userInfo = error.userInfo
        userInfo[NSURLSessionDownloadTaskResumeData] = nil
        return NSError(domain: error.domain, code: error.code, userInfo: userInfo)
    }
}
