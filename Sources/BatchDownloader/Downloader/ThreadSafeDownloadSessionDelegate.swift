//
//  ThreadSafeDownloadSessionDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/16/17.
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
import PromiseKit

protocol NetworkResponseCancellable: AnyObject {
    func cancel(batch: DownloadBatchResponse)
}

class ThreadSafeDownloadSessionDelegate: NetworkSessionDelegate, NetworkResponseCancellable {
    private let unsafeHandler: DownloadSessionDelegate
    private let queue: DispatchQueue

    var backgroundSessionCompletionHandler: (() -> Void)? {
        get { unsafeHandler.backgroundSessionCompletionHandler }
        set { unsafeHandler.backgroundSessionCompletionHandler = newValue }
    }

    init(unsafeHandler: DownloadSessionDelegate, queue: DispatchQueue) {
        self.unsafeHandler = unsafeHandler
        self.queue = queue
    }

    func populateRunningTasks(from session: NetworkSession) -> Promise<Void> {
        dispatchPrecondition(condition: .onQueue(queue))
        return session.tasks()
            .map(on: queue) { _, _, downloadTasks in
                try self.unsafeHandler.setRunningTasks(downloadTasks)
            }
    }

    func download(_ batch: DownloadBatchRequest) -> Promise<DownloadBatchResponse> {
        queue.async(.promise) {
            try self.unsafeHandler.download(batch)
        }
    }

    func getOnGoingDownloads() -> Guarantee<[DownloadBatchResponse]> {
        queue.async(.promise) {
            self.unsafeHandler.getOnGoingDownloads()
        }
    }

    func networkSession(_ session: NetworkSession,
                        downloadTask: NetworkSessionDownloadTask,
                        didWriteData bytesWritten: Int64,
                        totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64)
    {
        dispatchPrecondition(condition: .onQueue(queue))
        unsafeHandler.networkSession(session,
                                     downloadTask: downloadTask,
                                     didWriteData: bytesWritten,
                                     totalBytesWritten: totalBytesWritten,
                                     totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

    func networkSession(_ session: NetworkSession, downloadTask: NetworkSessionDownloadTask, didFinishDownloadingTo location: URL) {
        dispatchPrecondition(condition: .onQueue(queue))
        unsafeHandler.networkSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }

    func networkSession(_ session: NetworkSession, task: NetworkSessionTask, didCompleteWithError error: Error?) {
        dispatchPrecondition(condition: .onQueue(queue))
        unsafeHandler.networkSession(session, task: task, didCompleteWithError: error)
    }

    func networkSessionDidFinishEvents(forBackgroundURLSession session: NetworkSession) {
        dispatchPrecondition(condition: .onQueue(queue))
        unsafeHandler.networkSessionDidFinishEvents(forBackgroundURLSession: session)
    }

    func cancel(batch: DownloadBatchResponse) {
        queue.async(.promise) {
            try self.unsafeHandler.cancel(batch: batch)
        }
        .catch { error in
            crasher.recordError(error, reason: "Failed to cancel batch download.")
        }
    }
}
