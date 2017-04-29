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

import VFoundation

public struct DownloadNetworkBatchResponse {
    public let responses: [DownloadNetworkResponse]
    public subscript(_ index: Int) -> DownloadNetworkResponse {
        get { return responses[index] }
    }
}

open class DownloadNetworkResponse: Response {

    private weak var cancellable: NetworkResponseCancellable?

    open let task: URLSessionTask?
    open var download: Download

    open let progress: QProgress

    private var completions: [(Result<()>) -> Void] = []

    open var result: Result<()>? {
        didSet {
            if let result = result {
                for completion in completions {
                    completion(result)
                }
            }
        }
    }

    open func addCompletion(_ completion: @escaping (Result<()>) -> Void) {
        completions.append(completion)
        if let result = result {
            completion(result)
        }
    }

    public init(task: URLSessionTask?, download: Download, progress: QProgress, cancellable: NetworkResponseCancellable?) {
        self.task = task
        self.download = download
        self.progress = progress
        self.cancellable = cancellable
    }

    open func cancel() {
        cancellable?.cancel(self)
    }
}
