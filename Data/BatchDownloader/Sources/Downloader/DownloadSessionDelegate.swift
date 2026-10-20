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
import NetworkSupport
import SystemDependencies
import Utilities
import VLogging

actor DownloadSessionDelegate: NetworkSessionDelegate {
    // MARK: Lifecycle

    init(dataController: DownloadBatchDataController, fileManager: FileSystem) {
        self.dataController = dataController
        self.fileManager = fileManager
    }

    // MARK: Internal

    @MainActor var backgroundSessionCompletion: (@MainActor () -> Void)?

    /// The free space on the volume holding `directory`, measured at its nearest existing
    /// ancestor, since the directory may not exist yet.
    ///
    /// Reads real free space rather than the "important usage" capacity, which counts space
    /// the system could purge but a download can't write to yet.
    static func availableCapacity(at directory: URL) -> Int? {
        var existingDirectory = directory.standardizedFileURL
        while !FileManager.default.fileExists(atPath: existingDirectory.path), existingDirectory.pathComponents.count > 1 {
            existingDirectory = existingDirectory.deletingLastPathComponent()
        }
        do {
            let values = try existingDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return values.volumeAvailableCapacity
        } catch {
            logger.error("Couldn't read the available capacity at \(existingDirectory.path). Error: \(error)")
            return nil
        }
    }

    @MainActor
    func setBackgroundSessionCompletion(_ backgroundSessionCompletion: @MainActor @escaping () -> Void) {
        self.backgroundSessionCompletion = backgroundSessionCompletion
    }

    func networkSession(
        _ session: NetworkSession,
        downloadTask: NetworkSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) async {
        guard let response = await dataController.downloadRequestResponse(for: downloadTask) else {
            logger.warning("[networkSession:didWriteData] Cannot find onGoingDownloads for task \(describe(downloadTask))")
            return
        }
        let progress = DownloadProgress(total: Double(totalBytesExpectedToWrite), completed: Double(totalBytesWritten))
        await response.response.updateProgress(of: response.request, progress)
    }

    func networkSession(_ session: NetworkSession, downloadTask: NetworkSessionDownloadTask, didFinishDownloadingTo location: URL) async {
        // validate task response
        guard validate(task: downloadTask) == nil else {
            logger.error("Invalid server response \(downloadTask.taskIdentifier) - \(String(describing: downloadTask.response))")
            return
        }

        guard let response = await dataController.downloadRequestResponse(for: downloadTask) else {
            logger.warning("Missed saving task \(describe(downloadTask))")
            return
        }

        let resumePath = response.request.resumePath
        let destinationURL = response.request.destination

        // remove the resume data
        try? fileManager.removeItem(at: resumePath)
        // remove the existing file if exist.
        try? fileManager.removeItem(at: destinationURL)

        // create directory if needed
        let directory = destinationURL.deletingLastPathComponent()
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        // Downloaded resources can be fetched again, including files extracted here later.
        do {
            try fileManager.setExcludedFromBackup(true, at: directory)
        } catch {
            crasher.recordError(error, reason: "Couldn't exclude download directory from backup '\(directory)'")
        }

        // move the file to destination
        do {
            try fileManager.moveItem(at: location, to: destinationURL)

        } catch {
            crasher.recordError(
                error,
                reason: "Problem with creating directory or copying item to the new location '\(destinationURL)'"
            )
            // fail the batch since we save the file
            let fileError = FileSystemError(error: error, availableCapacity: Self.availableCapacity(at: directory.url))
            await dataController.downloadFailed(response, with: fileError)
        }
    }

    func networkSession(_ session: NetworkSession, task: NetworkSessionTask, didCompleteWithError sessionError: Error?) async {
        logger.debug("Finished downloading \(describe(task)). Error: \(String(describing: sessionError))")
        guard let response = await dataController.downloadRequestResponse(for: task) else {
            if let sessionError, !sessionError.isCancelled {
                logger.warning("[networkSession:didCompleteWithError] Cannot find onGoingDownloads for task \(describe(task))")
            }
            return
        }

        let validationError = validate(task: task)
        let theError = sessionError ?? validationError

        // if success, early return
        guard let error = theError else {
            await dataController.downloadCompleted(response)
            return
        }

        let finalError = wrap(error: error, request: response.request)
        await dataController.downloadFailed(response, with: finalError)
    }

    @MainActor
    func networkSessionDidFinishEvents(forBackgroundURLSession session: NetworkSession) {
        backgroundSessionCompletion?()
        backgroundSessionCompletion = nil
    }

    // MARK: Private

    private let acceptableStatusCodes = 200 ..< 300

    private let dataController: DownloadBatchDataController
    private let fileManager: FileSystem

    private func wrap(error theError: Error, request: DownloadRequest) -> Error {
        let resumePath = request.resumePath
        var error = theError

        // save resume data, if found
        if let resumeData = error.resumeData {
            do {
                try resumeData.write(to: resumePath, options: [.atomic])
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
        let directory = request.destination.url.deletingLastPathComponent()
        let finalError: Error = if FileSystemError.isNoDiskSpace(error, availableCapacity: Self.availableCapacity(at: directory)) {
            FileSystemError.noDiskSpace
        } else {
            NetworkError(error: error)
        }
        return finalError
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
