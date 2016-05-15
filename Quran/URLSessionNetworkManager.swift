//
//  URLSessionNetworkManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class URLSessionNetworkManager: NetworkManager {

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

    func getCurrentTasks(completion: (downloads: [Request]) -> Void) {
        // only query if there is download
        guard delegate.downloadRequests.isEmpty && delegate.isDownloading else {
            completion(downloads: delegate.downloadRequests.map { $1 })
            return
        }

        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTakss) in
            guard let `self` = self else {
                return
            }
            var downloads: [Request] = []
            for task in downloadTakss {
                if let request = task.originalRequest, let data = self.delegate.getRequestDataForRequest(request) {

                    let progress = NSProgress(totalUnitCount: 1)
                    let downloadRequest = DownloadNetworkRequest(task: task,
                        destination: data.destination,
                        resumeDestination: data.resumeData,
                        progress: progress)
                    self.delegate.addRequestData(request, downloadRequest: downloadRequest)
                    downloads.append(downloadRequest)
                }
            }
            completion(downloads: downloads)
        }
    }

    func download(request: NSURLRequest, destination: String, resumeDestination: String) -> Request {

        let task: NSURLSessionDownloadTask
        let resumeURL = Files.DocumentsFolder.URLByAppendingPathComponent(resumeDestination)
        if let data = NSData(contentsOfURL: resumeURL) {
            task = session.downloadTaskWithResumeData(data)
        } else {
            task = session.downloadTaskWithRequest(request)
        }
        let progress = NSProgress(totalUnitCount: 1)
        let downloadRequest = DownloadNetworkRequest(task: task,
                                             destination: destination,
                                             resumeDestination: resumeDestination,
                                             progress: progress)

        delegate.addRequestData(request, downloadRequest: downloadRequest)

        // start the task
        task.resume()
        return downloadRequest
    }
}
