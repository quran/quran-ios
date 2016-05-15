//
//  DownloadNetworkRequest.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class DownloadNetworkRequest: Request {

    let task: NSURLSessionDownloadTask
    let destination: String
    let resumeDestination: String

    let progress: NSProgress

    var onCompletion: (Result<()> -> Void)? = nil

    init(task: NSURLSessionDownloadTask, destination: String, resumeDestination: String, progress: NSProgress) {
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
        task.cancelByProducingResumeData { _ in }
    }
}
