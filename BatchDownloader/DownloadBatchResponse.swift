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
import PromiseKit
import VFoundation

class DownloadResponse {
    let progress: QProgress
    var download: Download
    var task: URLSessionTask?

    let promise: Promise<Void>
    let fulfill: (() -> Void)
    let reject: ((Error) -> Void)

    init( download: Download, progress: QProgress) {
        self.download = download
        self.progress = progress
        (promise, fulfill, reject) = Promise<Void>.pending()
    }
}

public final class DownloadBatchResponse {

    weak var cancellable: NetworkResponseCancellable?

    let batchId: Int64
    let responses: [DownloadResponse]

    public let progress: QProgress

    public let promise: Promise<Void>
    let fulfill: (() -> Void)
    let reject: ((Error) -> Void)

    public var requests: [DownloadRequest] {
        return responses.map { $0.download.request }
    }

    init(batchId: Int64, responses: [DownloadResponse], cancellable: NetworkResponseCancellable?) {
        self.batchId = batchId
        self.responses = responses
        self.cancellable = cancellable
        (promise, fulfill, reject) = Promise<Void>.pending()

        progress = QProgress(totalUnitCount: Double(responses.count))
        responses.forEach {
            progress.add(child: $0.progress, withPendingUnitCount: 1)
        }
    }

    public func cancel() {
        cancellable?.cancel(batch: self)
    }
}
