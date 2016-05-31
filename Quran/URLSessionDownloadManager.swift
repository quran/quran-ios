//
//  URLSessionDownloadManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class URLSessionDownloadManager: DownloadManager {

    let session: NSURLSession
    private let delegate: SessionDelegate

    var backgroundSessionCompletionHandler: (() -> Void)? {
        get {
            return delegate.backgroundSessionCompletionHandler
        }
        set {
            delegate.backgroundSessionCompletionHandler = newValue
        }
    }

    init(configuration: NSURLSessionConfiguration, persistence: SimplePersistence) {
        delegate = SessionDelegate(persistence: persistence)
        session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    func getCurrentTasks(completion: (downloads: [DownloadNetworkRequest]) -> Void) {
        // only query if there is download
        guard delegate.downloadRequests.isEmpty && delegate.isDownloading else {
            completion(downloads: delegate.downloadRequests.map { $1 })
            return
        }

        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTakss) in
            guard let `self` = self else {
                return
            }
            var downloads: [DownloadNetworkRequest] = []
            var requests = [(NSURLRequest, DownloadNetworkRequest)]()
            for task in downloadTakss {
                if let request = task.originalRequest, let data = self.delegate.getRequestDataForRequest(request) {

                    let progress = NSProgress(totalUnitCount: 1)
                    let downloadRequest = DownloadNetworkRequest(task: task,
                        destination: data.destination,
                        resumeDestination: data.resumeData,
                        progress: progress)
                    requests.append((request, downloadRequest: downloadRequest))
                    downloads.append(downloadRequest)
                }
            }
            self.delegate.addRequestsData(requests)
            completion(downloads: downloads)
        }
    }

    func download(requests: [(request: NSURLRequest, destination: String, resumeDestination: String)]) -> [DownloadNetworkRequest] {

        var downloadRequests = [(NSURLRequest, DownloadNetworkRequest)]()
        var tasks: [NSURLSessionDownloadTask] = []
        for details in requests {
            let task: NSURLSessionDownloadTask
            let resumeURL = Files.DocumentsFolder.URLByAppendingPathComponent(details.resumeDestination)
            if let data = NSData(contentsOfURL: resumeURL) {
                task = session.downloadTaskWithResumeData(data)
            } else {
                task = session.downloadTaskWithRequest(details.request)
            }
            let progress = NSProgress(totalUnitCount: 1)
            let downloadRequest = DownloadNetworkRequest(task: task,
                                                         destination: details.destination,
                                                         resumeDestination: details.resumeDestination,
                                                         progress: progress)
            tasks.append(task)
            downloadRequests.append((details.request, downloadRequest))
        }

        delegate.addRequestsData(downloadRequests)
        // start the tasks after the requests info are saved
        tasks.forEach { $0.resume() }

        return downloadRequests.map { $1 }
    }
}
