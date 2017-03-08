//
//  AudioFilesDownloadRequest.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class AudioFilesDownloadResponse: Response {

    let progress: Foundation.Progress

    let responses: [DownloadNetworkResponse]

    init(responses: [DownloadNetworkResponse], progress: Foundation.Progress) {
        self.responses = responses
        self.progress = progress
    }

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

    func resume() {
        responses.forEach { $0.resume() }
    }

    func suspend() {
        responses.forEach { $0.suspend() }
    }

    func cancel() {
        responses.forEach { $0.cancel() }
    }
}
