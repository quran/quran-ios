//
//  DownloadBatchResponse.swift
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
import PromiseKit

class DownloadResponse {
    let progress: QProgress
    var download: Download
    var task: NetworkSessionTask?

    let promise: Promise<Void>
    private let resolver: Resolver<Void>

    init(download: Download, progress: QProgress) {
        self.download = download
        self.progress = progress
        (promise, resolver) = Promise<Void>.pending()
    }

    func fulfill() {
        resolver.fulfill(())
    }

    func reject(_ error: Error) {
        resolver.reject(error)
    }
}

public final class DownloadBatchResponse {
    weak var cancellable: NetworkResponseCancellable?

    let batchId: Int64
    let responses: [DownloadResponse]

    public let progress: QProgress

    public let promise: Promise<Void>
    private let resolver: Resolver<Void>

    public var requests: [DownloadRequest] {
        responses.map(\.download.request)
    }

    init(batchId: Int64, responses: [DownloadResponse], cancellable: NetworkResponseCancellable?) {
        self.batchId = batchId
        self.responses = responses
        self.cancellable = cancellable
        (promise, resolver) = Promise<Void>.pending()

        progress = QProgress(totalUnitCount: Double(responses.count))
        responses.forEach {
            progress.add(child: $0.progress, withPendingUnitCount: 1)
        }
    }

    public func cancel() {
        if promise.isPending {
            cancellable?.cancel(batch: self)
        }
    }

    func fulfill() {
        resolver.fulfill(())
    }

    func reject(_ error: Error) {
        resolver.reject(error)
    }
}
