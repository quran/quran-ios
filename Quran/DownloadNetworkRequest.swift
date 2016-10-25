//
//  DownloadNetworkRequest.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class DownloadNetworkRequest: Request {

    let task: URLSessionDownloadTask
    let destination: String
    let resumeDestination: String

    let progress: Foundation.Progress

    var onCompletion: ((Result<()>) -> Void)? = nil

    init(task: URLSessionDownloadTask, destination: String, resumeDestination: String, progress: Foundation.Progress) {
        self.task = task
        self.destination = destination
        self.resumeDestination = resumeDestination
        self.progress = progress
    }

    func resume() {
        task.resume()
    }

    func suspend() {
        task.suspend()
    }

    func cancel() {
        task.cancel { _ in }
    }
}
