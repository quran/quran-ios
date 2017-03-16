//
//  DownloadSessionDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class DownloadSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {

    private let persistence: DownloadsPersistence

    private var onGoingDownloads: [Int: DownloadNetworkResponse] = [:]

    var backgroundSessionCompletionHandler: (() -> Void)?

    private var populated: Bool = false

    init(persistence: DownloadsPersistence) {
        self.persistence = persistence
    }

    func populateOnGoingDownloads(from session: URLSession, completion: (() -> Void)? = nil) {
        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTaks) in
            Queue.downloads.async { [weak self] _ in
                self?.populateOnGoingDownloads(onGoingDownloadTasks: downloadTaks, completion: completion)
            }
        }
    }

    private func populateOnGoingDownloads(onGoingDownloadTasks tasks: [URLSessionDownloadTask], completion: (() -> Void)? = nil) {
        guard !populated else {
            Queue.main.async { completion?() }
            return
        }
        guard let batches = try? persistence.retrieve(status: .downloading) else {
            return
        }

        // group tasks by id
        let tasksByIds: [Int: URLSessionDownloadTask] = tasks.flatGroup { $0.taskIdentifier }

        // loop over the batches
        for batch in batches {
            for download in batch.downloads {
                let taskId: Int = cast(download.taskId)
                if let task = tasksByIds[taskId] {
                    let progress = Foundation.Progress(totalUnitCount: 1)
                    let downloadRequest = DownloadNetworkResponse(task: task, download: download, progress: progress)
                    onGoingDownloads[taskId] = downloadRequest
                } else {
                    if download.status == .completed {
                        let progress = Foundation.Progress(totalUnitCount: 1)
                        progress.completedUnitCount = 1
                        let downloadRequest = DownloadNetworkResponse(task: nil, download: download, progress: progress)
                        onGoingDownloads[taskId] = downloadRequest
                    }
                    if download.status == .downloading {
                        try? persistence.update(url: download.url, newStatus: .failed)
                    }
                }
            }
        }
        populated = true
        Queue.main.async { completion?() }
    }

    func addOnGoingDownloads(_ downloads: [DownloadNetworkResponse]) {
        // create the onGoingDownloads once so we can use it before the persistence value is written.
        for download in downloads {
            let taskId: Int = cast(download.download.taskId)
            onGoingDownloads[taskId] = download
        }

        Queue.downloads.async { [weak self] in
            do {
                guard let `self` = self else { return }
                let downloadsToInsert = downloads.map { response -> Download in
                    var d = response.download
                    d.status = .downloading
                    return d
                }
                let batch = try self.persistence.insert(batch: downloadsToInsert)

                downloads.enumerated().forEach { (index, response) in
                    response.download = batch[index]
                }

                for download in downloads {
                    let taskId: Int = cast(download.download.taskId)
                    self.onGoingDownloads[taskId] = download
                }
            } catch {
                downloads.first?.result = .failure(error)
            }
        }
    }

    func getOnGoingDownloads() -> [[DownloadNetworkResponse]] {
        let groups = onGoingDownloads.values.group { $0.download.batchId ?? 0 }
        return groups.map { $1 }
    }

    private func responsesForBatch(_ batchId: Int64?) -> [DownloadNetworkResponse] {
        guard let batchId = batchId else { return [] }
        return onGoingDownloads.filter { $1.download.batchId == batchId }.map { $1 }
    }

    private func taskFailed(_ task: URLSessionTask) -> DownloadNetworkResponse? {
        return update(taskId: task.taskIdentifier, status: .failed)
    }

    private func taskCompleted(_ task: URLSessionTask) -> DownloadNetworkResponse? {
        return update(taskId: task.taskIdentifier, status: .completed)
    }

    private func update(taskId: Int, status: Download.Status) -> DownloadNetworkResponse? {
        guard let downloadRequest = onGoingDownloads[taskId] else {
            return nil
        }
        var download = downloadRequest.download
        download.status = status
        downloadRequest.download = download
        onGoingDownloads[taskId] = downloadRequest

        // delete the batch if all completed/failed
        let responses = responsesForBatch(download.batchId)
        if !responses.contains { $0.download.status == .downloading } {
            for response in responses {
                let taskId: Int = cast(response.download.taskId)
                onGoingDownloads[taskId] = nil
            }
        }

        Queue.downloads.async {
            try? self.persistence.update(url: download.url, newStatus: status)
        }
        return downloadRequest
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let response = onGoingDownloads[downloadTask.taskIdentifier] else {
            CLog("Cannot find onGoingDownloads for task with id \(downloadTask.taskIdentifier) - \(downloadTask.currentRequest?.url)")
            return
        }
        response.progress.totalUnitCount = totalBytesExpectedToWrite
        response.progress.completedUnitCount = totalBytesWritten
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
       urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location, firstTime: true)
    }

    private func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL, firstTime: Bool) {
        // move the file to the correct location
        if let download = onGoingDownloads[downloadTask.taskIdentifier]?.download {
            let fileManager = FileManager.default

            let resumeURL = FileManager.default.documentsURL.appendingPathComponent(download.resumePath)
            let destinationURL = FileManager.default.documentsURL.appendingPathComponent(download.destinationPath)

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
                try fileManager.copyItem(at: location, to: destinationURL)


            } catch {
                Crash.recordError(error, reason: "Problem with create directory or copying item to the new location '\(destinationURL)'",
                    fatalErrorOnDebug: false)
                // early exist with error
                let downloadRequest = taskFailed(downloadTask)
                downloadRequest?.result = .failure(FileSystemError(error: error))
            }
        } else {
            if firstTime {
                // move the file to a temprarily location
                let tempFileURL = FileManager.default.tempFileURL
                do {
                    try FileManager.default.copyItem(at: location, to: tempFileURL)
                } catch {
                    Crash.recordError(error, reason: "Error copying the file to a temp file location")
                }
                populateOnGoingDownloads(from: session, completion: { [weak self] in
                    self?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: tempFileURL, firstTime: false)
                    try? FileManager.default.removeItem(at: tempFileURL)
                })
            } else {
                print("Missed saving task", downloadTask.currentRequest?.url as Any)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Queue.downloads.async { [weak self] in
            // remove the request
            let response: DownloadNetworkResponse?
            if error != nil {
                response = self?.taskFailed(task)
            } else {
                response = self?.taskCompleted(task)
            }

            if let error = error {
                print("Network error occurred: \(error)")

                // save resume data, if found
                if let resumePath = response?.download.resumePath,
                    let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    let resumeURL = FileManager.default.documentsURL.appendingPathComponent(resumePath)
                    try? resumeData.write(to: resumeURL, options: [.atomic])
                }

                if ((error as? URLError)?.code) != URLError.cancelled { // not cancelled by user
                    let finalError: Error
                    if error is POSIXErrorCode && Int32((error as NSError).code) == ENOENT {
                        finalError = FileSystemError.noDiskSpace
                    } else {
                        finalError = NetworkError(error: error)
                    }
                    response?.result = .failure(finalError)
                }
            } else {
                // success
                response?.result = .success()
            }
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let handler = backgroundSessionCompletionHandler
        backgroundSessionCompletionHandler = nil
        handler?()
    }

    fileprivate func createDirectoryForPath(_ path: URL) {
        let directory = path.deletingLastPathComponent()
        // ignore errors
        try? FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
}
