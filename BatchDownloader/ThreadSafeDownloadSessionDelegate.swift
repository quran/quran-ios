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
import PromiseKit
import VFoundation

protocol NetworkResponseCancellable: class {
    func cancel(batch: DownloadBatchResponse)
}

class ThreadSafeDownloadSessionDelegate: NSObject, URLSessionDownloadDelegate, NetworkResponseCancellable {

    private let unsafeHandler: DownloadSessionDelegate
    private let queue: OperationQueue

    var backgroundSessionCompletionHandler: (() -> Void)? {
        get { return unsafeHandler.backgroundSessionCompletionHandler }
        set { unsafeHandler.backgroundSessionCompletionHandler = newValue }
    }

    init(unsafeHandler: DownloadSessionDelegate, queue: OperationQueue) {
        self.unsafeHandler = unsafeHandler
        self.queue = queue
    }

    func populateRunningTasks(from session: URLSession) {
        session.getTasks()
            .then { (_, _, downloadTasks) in
                self.queue.async(.promise) {
                    try self.unsafeHandler.setRunningTasks(downloadTasks)
                }
            }.cauterize()
    }

    func download(_ batch: DownloadBatchRequest) -> Promise<DownloadBatchResponse> {
        return queue.async(.promise) {
            try self.unsafeHandler.download(batch)
        }
    }

    func getOnGoingDownloads() -> Guarantee<[DownloadBatchResponse]> {
        return queue.async(.promise) {
            self.unsafeHandler.getOnGoingDownloads()
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        unsafeHandler.urlSession(session,
                                 downloadTask: downloadTask,
                                 didWriteData: bytesWritten,
                                 totalBytesWritten: totalBytesWritten,
                                 totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        unsafeHandler.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        unsafeHandler.urlSession(session, task: task, didCompleteWithError: error)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        unsafeHandler.urlSessionDidFinishEvents(forBackgroundURLSession: session)
    }

    func cancel(batch: DownloadBatchResponse) {
        queue.async(.promise) {
            try self.unsafeHandler.cancel(batch: batch)
        }.cauterize()
    }
}
