//
//  URLSessionDownloadManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class URLSessionDownloadManager: DownloadManager {

    let session: URLSession

    // swiftlint:disable weak_delegate
    fileprivate let delegate: DownloadSessionDelegate

    var backgroundSessionCompletionHandler: (() -> Void)? {
        get {
            return delegate.backgroundSessionCompletionHandler
        }
        set {
            delegate.backgroundSessionCompletionHandler = newValue
        }
    }

    init(configuration: URLSessionConfiguration, persistence: DownloadsPersistence) {
        delegate = DownloadSessionDelegate(persistence: persistence)
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    func populateOnGoingDownloads() {
        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTaks) in
            self?.delegate.populateOnGoingDownloads(onGoingDownloadTasks: downloadTaks)
        }
    }

    func getOnGoingDownloads() -> [[DownloadNetworkResponse]] {
        return delegate.getOnGoingDownloads()
    }

    func download(_ requests: [Download]) -> [DownloadNetworkResponse] {

        var responses = [DownloadNetworkResponse]()
        var tasks: [URLSessionDownloadTask] = []
        for download in requests {
            let request = URLRequest(url: download.url)
            let task: URLSessionDownloadTask
            let resumeURL = FileManager.default.documentsURL.appendingPathComponent(download.resumePath)
            if let data = try? Data(contentsOf: resumeURL) {
                task = session.downloadTask(withResumeData: data)
            } else {
                task = session.downloadTask(with: request)
            }
            tasks.append(task)

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
