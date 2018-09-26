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

class DownloadSessionDelegate: NSObject, URLSessionDownloadDelegate {

    private let acceptableStatusCodes = 200..<300

    private let dataController: DownloadBatchDataController

    weak var cancellable: NetworkResponseCancellable?
    var backgroundSessionCompletionHandler: (() -> Void)?

    init(dataController: DownloadBatchDataController) {
        self.dataController = dataController
    }

    func setRunningTasks(_ tasks: [URLSessionTask]) throws {
        try dataController.setRunningTasks(tasks)
    }

    func download(_ batch: DownloadBatchRequest) throws -> DownloadBatchResponse {
        return try dataController.download(batch)
    }

    func getOnGoingDownloads() -> [DownloadBatchResponse] {
        return dataController.getOnGoingDownloads().map { $1 }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let response = dataController.downloadResponse(for: downloadTask) else {
            log("Cannot find onGoingDownloads for task", describe(downloadTask))
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

        guard let response = dataController.downloadResponse(for: downloadTask) else {
            log("Missed saving task", describe(downloadTask))
            return
        }
        let fileManager = FileManager.default

        let resumeURL = FileManager.documentsURL.appendingPathComponent(response.download.request.resumePath)
        let destinationURL = FileManager.documentsURL.appendingPathComponent(response.download.request.destinationPath)

        // remove the resume data
        try? fileManager.removeItem(at: resumeURL)
        // remove the existing file if exist.
        try? fileManager.removeItem(at: destinationURL)

        // create directory if needed
        let directory = destinationURL.deletingLastPathComponent()
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

        // move the file to destination
        do {
            try fileManager.moveItem(at: location, to: destinationURL)

        } catch {
            Crash.recordError(error,
                              reason: "Problem with create directory or copying item to the new location '\(destinationURL)'",
                              fatalErrorOnDebug: false)
            // fail the batch since we save the file
            do {
                try dataController.downloadFailed(response, with: FileSystemError(error: error))
            } catch {
                Crash.recordError(error, reason: "downloadFailed", fatalErrorOnDebug: false)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError sessionError: Error?) {

        guard let response = dataController.downloadResponse(for: task) else {
            log("Cannot find onGoingDownloads for task", describe(task))
            return
        }

        let validationError = validate(task: task)
        let theError = sessionError ?? validationError

        // if success, early return
        guard let error = theError else {
            do {
                try dataController.downloadCompleted(response)
            } catch {
                Crash.recordError(error, reason: "downloadCompleted", fatalErrorOnDebug: false)
            }
            return
        }

        let finalError = wrap(error: error, resumePath: response.download.request.resumePath)

        do {
            try dataController.downloadFailed(response, with: finalError)
        } catch {
            Crash.recordError(error, reason: "downloadFailed", fatalErrorOnDebug: false)
        }
    }

    private func wrap(error theError: Error, resumePath: String) -> Error {
        var error = theError

        // save resume data, if found
        if let resumeData = error.resumeData {
            let resumeURL = FileManager.documentsURL.appendingPathComponent(resumePath)
            suppress {
                try resumeData.write(to: resumeURL, options: [.atomic])
            }
            error = error.removeResumeData()
        }

        // not cancelled by user
        guard !error.isCancelled else {
            return error
        }

        Crash.recordError(error, reason: "Download network error occurred", fatalErrorOnDebug: false)

        // check if no disk space
        let finalError: Error
        if error is POSIXErrorCode && Int32((error as NSError).code) == ENOENT {
            finalError = FileSystemError.noDiskSpace
        } else {
            finalError = NetworkError(error: error)
        }
        return finalError
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let handler = backgroundSessionCompletionHandler
        backgroundSessionCompletionHandler = nil
        handler?()
    }

    func cancel(batch: DownloadBatchResponse) throws {
        try dataController.cancel(batch: batch)
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
