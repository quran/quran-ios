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
    fileprivate let delegate: SessionDelegate

    var backgroundSessionCompletionHandler: (() -> Void)? {
        get {
            return delegate.backgroundSessionCompletionHandler
        }
        set {
            delegate.backgroundSessionCompletionHandler = newValue
        }
    }

    init(configuration: URLSessionConfiguration, persistence: SimplePersistence) {
        delegate = SessionDelegate(persistence: persistence)
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    func getCurrentTasks(_ completion: @escaping (_ downloads: [DownloadNetworkRequest]) -> Void) {
        // only query if there is download
        guard delegate.downloadRequests.isEmpty && delegate.isDownloading else {
            completion(delegate.downloadRequests.map { $1 })
            return
        }

        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTakss) in
            guard let `self` = self else {
                return
            }
            var downloads: [DownloadNetworkRequest] = []
            var requests = [(URLRequest, DownloadNetworkRequest)]()
            for task in downloadTakss {
                if let request = task.originalRequest, let data = self.delegate.getRequestDataForRequest(request) {

                    let progress = Foundation.Progress(totalUnitCount: 1)
                    let downloadRequest = DownloadNetworkRequest(task: task,
                        destination: data.destination,
                        resumeDestination: data.resumeData,
                        progress: progress)
                    requests.append((request, downloadRequest: downloadRequest))
                    downloads.append(downloadRequest)
                }
            }
            self.delegate.addRequestsData(requests)
            completion(downloads)
        }
    }

    func download(_ requests: [DownloadInformation]) -> [DownloadNetworkRequest] {

        var downloadRequests = [(URLRequest, DownloadNetworkRequest)]()
        var tasks: [URLSessionDownloadTask] = []
        for details in requests {
            let request = URLRequest(url: details.remoteURL)
            let task: URLSessionDownloadTask
            let resumeURL = FileManager.default.documentsURL.appendingPathComponent(details.resumeURL)
            if let data = try? Data(contentsOf: resumeURL) {
                task = session.downloadTask(withResumeData: data)
            } else {
                task = session.downloadTask(with: request)
            }
            let progress = Foundation.Progress(totalUnitCount: 1)
            let downloadRequest = DownloadNetworkRequest(task: task,
                                                         destination: details.destination,
                                                         resumeDestination: details.resumeURL,
                                                         progress: progress)
            tasks.append(task)
            downloadRequests.append((request, downloadRequest))
        }

        delegate.addRequestsData(downloadRequests)
        // start the tasks after the requests info are saved
        tasks.forEach { $0.resume() }

        return downloadRequests.map { $1 }
    }
}
