//
//  DownloadNetworkResponse.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class DownloadNetworkResponse: Response {

    let task: URLSessionTask?
    var download: Download

    let progress: Foundation.Progress

    var result: Result<()>? {
        didSet {
            if let result = result {
                onCompletion?(result)
            }
        }
    }

    var onCompletion: ((Result<()>) -> Void)? {
        didSet {
            if let result = result {
                onCompletion?(result)
            }
        }
    }

    init(task: URLSessionTask?, download: Download, progress: Foundation.Progress) {
        self.task = task
        self.download = download
        self.progress = progress
    }

    func resume() {
        task?.resume()
    }

    func suspend() {
        task?.suspend()
    }

    func cancel() {
        task?.cancel()
    }
}
