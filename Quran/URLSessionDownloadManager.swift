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

import Foundation
import PromiseKit

class URLSessionDownloadManager: DownloadManager {

    let session: URLSession

    // Intentially retained
    // swiftlint:disable weak_delegate
    private let delegate: ThreadSafeDownloadSessionDelegate

    private let delegateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.quran.downloads"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    var backgroundSessionCompletionHandler: (() -> Void)? {
        get {
            return delegate.backgroundSessionCompletionHandler
        }
        set {
            delegate.backgroundSessionCompletionHandler = newValue
        }
    }

    init(configuration: URLSessionConfiguration, persistence: DownloadsPersistence) {
        let handler = DownloadSessionDelegate(persistence: persistence, queue: delegateQueue)
        self.delegate = ThreadSafeDownloadSessionDelegate(handler: handler, queue: delegateQueue)
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        populateOnGoingDownloads()
    }

    private func populateOnGoingDownloads() {
        delegate.populateOnGoingDownloads(from: session)
    }

    func getOnGoingDownloads() -> Promise<[[DownloadNetworkResponse]]> {
        return delegate.getOnGoingDownloads()
    }

    func download(_ requests: [Download]) -> [DownloadNetworkResponse] {

        var responses = [DownloadNetworkResponse]()
        var tasks: [URLSessionDownloadTask] = []
        for var download in requests {
            let request = URLRequest(url: download.url)
            let task: URLSessionDownloadTask
            let resumeURL = FileManager.default.documentsURL.appendingPathComponent(download.resumePath)
            if let data = try? Data(contentsOf: resumeURL) {
                task = session.downloadTask(withResumeData: data)
            } else {
                task = session.downloadTask(with: request)
            }
            tasks.append(task)
            download.taskId = task.taskIdentifier

            let progress = Foundation.Progress(totalUnitCount: 1)
            let response = DownloadNetworkResponse(task: task, download: download, progress: progress)
            responses.append(response)
        }

        delegate.addOnGoingDownloads(responses)
        // start the tasks after the requests info are saved
        tasks.forEach { $0.resume() }

        return responses
    }
}
