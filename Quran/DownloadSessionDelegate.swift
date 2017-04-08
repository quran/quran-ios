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

import Foundation
import UIKit

class DownloadSessionDelegate: NSObject, URLSessionDownloadHandler {

    private let persistence: DownloadsPersistence

    private var downloadingResponses: [Int: DownloadNetworkResponse] = [:]

    var backgroundSessionCompletionHandler: (() -> Void)?

    private var downloadBatches: [DownloadBatch] = []

    private var populated = false

    init(persistence: DownloadsPersistence, queue: OperationQueue) {
        self.persistence = persistence
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
        let progress = Progress(totalUnitCount: 1)
        let downloadRequest = DownloadNetworkResponse(task: task, download: download, progress: progress)
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
                    let taskId: Int = cast(item.download.taskId)
                    downloadingResponses[taskId] = nil
                }
                safely("cleanUpDownloads") {
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
            let taskId: Int = cast(download.taskId)
            guard downloadingResponses[taskId] == nil else {
                continue
            }
            if let task = tasksByIds[taskId] {
                let progress = Progress(totalUnitCount: 1)
                let downloadRequest = DownloadNetworkResponse(task: task, download: download, progress: progress)
                downloadingResponses[taskId] = downloadRequest
            } else {
                if download.status == .completed {
                    let progress = Progress(totalUnitCount: 1)
                    progress.completedUnitCount = 1
                    let downloadRequest = DownloadNetworkResponse(task: nil, download: download, progress: progress)
                    downloadingResponses[taskId] = downloadRequest
                } else if download.status == .downloading {
                    // set it as failed
                    safely("populateOnGoingDownloads") {
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
            let taskId: Int = cast(download.download.taskId)
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
                let taskId: Int = cast(response.download.taskId)
                downloadingResponses[taskId] = response
            }
        } catch {
            Crash.recordError(error, reason: "addOnGoingDownloads")
            downloads.first?.result = .failure(error)
        }
    }

    func getOnGoingDownloads() -> [[DownloadNetworkResponse]] {
        let groups = downloadingResponses.values.group { $0.download.batchId ?? 0 }
        return groups.map { $1 }
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

        safely("update(task:status:)") {
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
            CLog("Cannot find onGoingDownloads for task with id \(downloadTask.taskIdentifier) - \(downloadTask.currentRequest?.url)")
            return
        }
        response.progress.totalUnitCount = totalBytesExpectedToWrite
        response.progress.completedUnitCount = totalBytesWritten
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let download = response(for: downloadTask)?.download else {
            CLog("Missed saving task", downloadTask.currentRequest?.url as Any)
            return
        }
        let fileManager = FileManager.default

        let resumeURL = fileManager.documentsURL.appendingPathComponent(download.resumePath)
        let destinationURL = fileManager.documentsURL.appendingPathComponent(download.destinationPath)

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

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // remove the request
        let networkResponse: DownloadNetworkResponse?
        if let error = error {
            CLog("Download network error occurred:", error)
            networkResponse = taskFailed(task)
        } else {
            networkResponse = taskCompleted(task)
        }
        guard let response = networkResponse else {
            return
        }

        // if success, early return
        guard let error = error else {
            response.result = .success()
            return
        }

        // save resume data, if found
        if let resumeData = error.resumeData {
            let resumeURL = FileManager.default.documentsURL.appendingPathComponent(response.download.resumePath)
            safely("save.resume.data") {
                try resumeData.write(to: resumeURL, options: [.atomic])
            }
        }

        // not cancelled by user
        guard !error.isCancelled else {
            return
        }

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
}

extension Error {
    fileprivate var resumeData: Data? {
        return (self as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    }

    fileprivate var isCancelled: Bool {
        return (self as? URLError)?.code == URLError.cancelled
    }
}
