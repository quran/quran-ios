//
//  DownloadSessionDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

private struct URL: Hashable {
    let string: String
    init(_ url: Foundation.URL) {
        string = (url.host ?? "") + url.path
    }

    var hashValue: Int { return string.hashValue }

    static func == (lhs: URL, rhs: URL) -> Bool {
        return lhs.string == rhs.string
    }
}

extension URLSessionTask {

    fileprivate var url: URL? {
        if let request = originalRequest ?? currentRequest {
            return request.url.map { URL($0) }
        }
        return nil
    }
}

class DownloadSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {

    private let persistence: DownloadsPersistence

    private var onGoingDownloads: [URL: DownloadNetworkResponse] = [:]

    var backgroundSessionCompletionHandler: (() -> Void)?

    init(persistence: DownloadsPersistence) {
        self.persistence = persistence
    }

    func populateOnGoingDownloads(onGoingDownloadTasks tasks: [URLSessionDownloadTask]) {

        Queue.downloads.async { [weak self] in
            guard let batches = (try? self?.persistence.retrieve(status: .downloading)).flatMap({ $0 }) else {
                return
            }

            // group tasks by url
            var tasksByURL: [URL: URLSessionDownloadTask] = [:]
            for task in tasks {
                if let url = task.url {
                    tasksByURL[url] = task
                }
            }

            // loop over the batches
            for batch in batches {
                for download in batch.downloads {
                    if let task = tasksByURL[URL(download.url)] {
                        let progress = Foundation.Progress(totalUnitCount: 1)
                        let downloadRequest = DownloadNetworkResponse(task: task, download: download, progress: progress)
                        self?.onGoingDownloads[URL(download.url)] = downloadRequest
                    } else {
                        if download.status == .completed {
                            let progress = Foundation.Progress(totalUnitCount: 1)
                            progress.completedUnitCount = 1
                            let downloadRequest = DownloadNetworkResponse(task: nil, download: download, progress: progress)
                            self?.onGoingDownloads[URL(download.url)] = downloadRequest
                        }
                        if download.status == .downloading {
                            try? self?.persistence.update(url: download.url, newStatus: .failed)
                        }
                    }
                }
            }
        }
    }

    func addOnGoingDownloads(_ downloads: [DownloadNetworkResponse]) {
        Queue.downloads.async { [weak self] in
            let batch = ((try? self?.persistence.insert(batch: downloads.map { $0.download })) ?? []) ?? []

            downloads.enumerated().forEach { (index, response) in
                response.download = batch[index]
            }

            for download in downloads {
                self?.onGoingDownloads[URL(download.download.url)] = download
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
        guard let url = task.url else {
            return nil
        }
        return update(url: url, status: .failed)
    }

    private func taskCompleted(_ task: URLSessionTask) -> DownloadNetworkResponse? {
        guard let url = task.url else {
            return nil
        }
        return update(url: url, status: .completed)
    }

    private func update(url: URL, status: Download.Status) -> DownloadNetworkResponse? {
        guard let downloadRequest = onGoingDownloads[url] else {
            return nil
        }
        var download = downloadRequest.download
        download.status = status
        downloadRequest.download = download
        onGoingDownloads[url] = downloadRequest

        // delete the batch if all completed/failed
        let responses = responsesForBatch(download.batchId)
        if !responses.contains { $0.download.status == .downloading } {
            for response in responses {
                onGoingDownloads[URL(response.download.url)] = nil
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

        guard let request = downloadTask.originalRequest else {
            return
        }

        guard let url = request.url else {
            return
        }

        guard let response = onGoingDownloads[URL(url)] else {
            return
        }
        response.progress.totalUnitCount = totalBytesExpectedToWrite
        response.progress.completedUnitCount = totalBytesWritten
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: Foundation.URL) {

        guard let url = downloadTask.url else {
            return
        }

        // move the file to the correct location
        if let download = onGoingDownloads[url]?.download {
            let fileManager = FileManager.default

            let resumeURL = FileManager.default.documentsURL.appendingPathComponent(download.resumePath)
            let destinationURL = FileManager.default.documentsURL.appendingPathComponent(download.destinationPath)

            // remove the resume data
            let _ = try? fileManager.removeItem(at: resumeURL)
            // remove the existing file if exist.
            let _ = try? fileManager.removeItem(at: destinationURL)

            // move the file to destination
            do {
                let directory = destinationURL.deletingLastPathComponent()
                let _ = try? fileManager.createDirectory(at: directory,
                                withIntermediateDirectories: true,
                                                 attributes: nil)
                try fileManager.copyItem(at: location, to: destinationURL)


            } catch let error {
                Crash.recordError(error, reason: "Problem with create directory or copying item to the new location '\(destinationURL)'",
                    fatalErrorOnDebug: false)
                // early exist with error
                let downloadRequest = taskFailed(downloadTask)
                downloadRequest?.onCompletion?(.failure(FileSystemError(error: error)))
            }
        } else {
            print("Missed saving task", downloadTask.currentRequest?.url as Any)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // remove the request
        let response: DownloadNetworkResponse?
        if error != nil {
            response = taskFailed(task)
        } else {
            response = taskCompleted(task)
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
                response?.onCompletion?(.failure(finalError))
            }
        } else {
            // success
            response?.onCompletion?(.success())
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let handler = backgroundSessionCompletionHandler
        backgroundSessionCompletionHandler = nil
        handler?()
    }

    fileprivate func createDirectoryForPath(_ path: Foundation.URL) {
        let directory = path.deletingLastPathComponent()
        // ignore errors
        let _ = try? FileManager.default.createDirectory(at: directory,
                                withIntermediateDirectories: true,
                                                 attributes: nil)
    }
}
