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

import Crashing
import Foundation
import VLogging

actor DownloadSessionDelegate: NetworkSessionDelegate {
    private let acceptableStatusCodes = 200 ..< 300

    private let dataController: DownloadBatchDataController

    @MainActor var backgroundSessionCompletion: (() -> Void)?

    init(dataController: DownloadBatchDataController) {
        self.dataController = dataController
    }

    @MainActor
    func setBackgroundSessionCompletion(_ backgroundSessionCompletion: (() -> Void)?) {
        self.backgroundSessionCompletion = backgroundSessionCompletion
    }

    func networkSession(_ session: NetworkSession,
                        downloadTask: NetworkSessionDownloadTask,
                        didWriteData bytesWritten: Int64,
                        totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64) async
    {
        guard let response = await dataController.downloadResponse(for: downloadTask) else {
            logger.warning("[networkSession:didWriteData] Cannot find onGoingDownloads for task \(describe(downloadTask))")
            return
        }
        await response.updateProgress(DownloadProgress(total: Double(totalBytesExpectedToWrite), completed: Double(totalBytesWritten)))
    }

    func networkSession(_ session: NetworkSession, downloadTask: NetworkSessionDownloadTask, didFinishDownloadingTo location: URL) async {
        // validate task response
        guard validate(task: downloadTask) == nil else {
            logger.error("Invalid server response \(downloadTask.taskIdentifier) - \(String(describing: downloadTask.response))")
            return
        }

        guard let response = await dataController.downloadResponse(for: downloadTask) else {
            logger.warning("Missed saving task \(describe(downloadTask))")
            return
        }
        let fileManager = FileManager.default

        let resumeURL = FileManager.documentsURL.appendingPathComponent(await response.download.request.resumePath)
        let destinationURL = FileManager.documentsURL.appendingPathComponent(await response.download.request.destinationPath)

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
            crasher.recordError(
                error,
                reason: "Problem with creating directory or copying item to the new location '\(destinationURL)'"
            )
            // fail the batch since we save the file
            await dataController.downloadFailed(response, with: FileSystemError(error: error))
        }
    }

    func networkSession(_ session: NetworkSession, task: NetworkSessionTask, didCompleteWithError sessionError: Error?) async {
        guard let response = await dataController.downloadResponse(for: task) else {
            logger.warning("[networkSession:didCompleteWithError] Cannot find onGoingDownloads for task \(describe(task))")
            return
        }

        let validationError = validate(task: task)
        let theError = sessionError ?? validationError

        // if success, early return
        guard let error = theError else {
            await dataController.downloadCompleted(response)
            return
        }

        let finalError = wrap(error: error, resumePath: await response.download.request.resumePath)
        await dataController.downloadFailed(response, with: finalError)
    }

    private func wrap(error theError: Error, resumePath: String) -> Error {
        var error = theError

        // save resume data, if found
        if let resumeData = error.resumeData {
            let resumeURL = FileManager.documentsURL.appendingPathComponent(resumePath)
            do {
                try resumeData.write(to: resumeURL, options: [.atomic])
            } catch {
                crasher.recordError(error, reason: "Error while saving resume data.")
            }
            error = error.removeResumeData()
        }

        // not cancelled by user
        guard !error.isCancelled else {
            return error
        }

        crasher.recordError(error, reason: "Download network error occurred")

        // check if no disk space
        let finalError: Error
        if let error = error as? POSIXError, error.code == .ENOENT {
            finalError = FileSystemError.noDiskSpace
        } else {
            finalError = NetworkError(error: error)
        }
        return finalError
    }

    @MainActor
    func networkSessionDidFinishEvents(forBackgroundURLSession session: NetworkSession) {
        backgroundSessionCompletion?()
        backgroundSessionCompletion = nil
    }

    private func validate(task: NetworkSessionTask) -> Error? {
        let httpResponse = task.response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        if !acceptableStatusCodes.contains(statusCode) {
            return NetworkError.serverError("Unacceptable status code: \(statusCode)")
        } else {
            return nil
        }
    }
}

private extension Error {
    var resumeData: Data? {
        (self as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    }

    var isCancelled: Bool {
        (self as? URLError)?.code == URLError.cancelled
    }

    func removeResumeData() -> Error {
        let error = self as NSError
        guard error.userInfo[NSURLSessionDownloadTaskResumeData] != nil else {
            return self
        }
        var userInfo = error.userInfo
        userInfo[NSURLSessionDownloadTaskResumeData] = nil
        return NSError(domain: error.domain, code: error.code, userInfo: userInfo)
    }
}
