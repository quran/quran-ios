//
//  DownloadNetworkResponse.swift
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

struct DownloadNetworkBatchResponse {
    let responses: [DownloadNetworkResponse]
    subscript(_ index: Int) -> DownloadNetworkResponse {
        get { return responses[index] }
    }

    var isAudio: Bool {
        return responses.first(where: { !$0.download.isAudio }) == nil
    }
}

class DownloadNetworkResponse: Response {

    private weak var cancellable: NetworkResponseCancellable?

    let task: URLSessionTask?
    var download: Download

    let progress: Progress

    private var completions: [(Result<()>) -> Void] = []

    var result: Result<()>? {
        didSet {
            if let result = result {
                for completion in completions {
                    completion(result)
                }
            }
        }
    }

    func addCompletion(_ completion: @escaping (Result<()>) -> Void) {
        completions.append(completion)
        if let result = result {
            completion(result)
        }
    }

    init(task: URLSessionTask?, download: Download, progress: Progress, cancellable: NetworkResponseCancellable?) {
        self.task = task
        self.download = download
        self.progress = progress
        self.cancellable = cancellable
    }

    func cancel() {
        cancellable?.cancel(self)
    }
}
