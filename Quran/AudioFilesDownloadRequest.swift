//
//  AudioFilesDownloadRequest.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class AudioFilesDownloadRequest: Request {

    let progress: NSProgress

    let requests: [DownloadNetworkRequest]

    init(requests: [DownloadNetworkRequest], progress: NSProgress) {
        self.requests = requests
        self.progress = progress
    }

    var onCompletion: (Result<()> -> Void)?

    func resume() {
        requests.forEach { $0.resume() }
    }

    func suspend() {
        requests.forEach { $0.suspend() }
    }

    func cancel() {
        requests.forEach { $0.cancel() }
    }
}
