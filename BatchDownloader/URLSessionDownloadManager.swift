//
//  URLSessionDownloadManager.swift
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
import PromiseKit

open class URLSessionDownloadManager: DownloadManager {

    open let session: URLSession

    // Intentially retained
    // swiftlint:disable weak_delegate
    private let delegate: ThreadSafeDownloadSessionDelegate

    private let delegateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.quran.downloads"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    open var backgroundSessionCompletionHandler: (() -> Void)? {
        get {
            return delegate.backgroundSessionCompletionHandler
        }
        set {
            delegate.backgroundSessionCompletionHandler = newValue
        }
    }

    public init(configuration: URLSessionConfiguration, persistence: DownloadsPersistence) {
        let handler = DownloadSessionDelegate(persistence: persistence, queue: delegateQueue)
        self.delegate = ThreadSafeDownloadSessionDelegate(handler: handler, queue: delegateQueue)
        handler.cancellable = self.delegate
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        populateOnGoingDownloads()
    }

    private func populateOnGoingDownloads() {
        delegate.populateOnGoingDownloads(from: session)
    }

    open func getOnGoingDownloads() -> Promise<[DownloadNetworkBatchResponse]> {
        return delegate.getOnGoingDownloads()
    }

    open func download(_ requests: [Download]) -> [DownloadNetworkResponse] {

        var responses = [DownloadNetworkResponse]()
        var tasks: [URLSessionDownloadTask] = []
        for var download in requests {
            let request = URLRequest(url: download.url)
            let task: URLSessionDownloadTask
            let resumeURL = FileManager.documentsURL.appendingPathComponent(download.resumePath)
            if let data = try? Data(contentsOf: resumeURL) {
                task = session.downloadTask(withResumeData: data)
            } else {
                task = session.downloadTask(with: request)
            }
            tasks.append(task)
            download.taskId = task.taskIdentifier

            let progress = QProgress(totalUnitCount: 1)
            let response = DownloadNetworkResponse(task: task, download: download, progress: progress, cancellable: delegate)
            responses.append(response)
        }

        // save them to persistence
        delegate.addOnGoingDownloads(responses)

        // start the tasks after the requests info are saved
        for task in tasks {
            task.resume()
        }

        return responses
    }
}
