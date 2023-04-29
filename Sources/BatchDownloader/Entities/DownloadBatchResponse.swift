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

import Combine
import Crashing
import Foundation
import PromiseKit

class DownloadResponse {
    let progressSubject = CurrentValueSubject<DownloadProgress, Never>(DownloadProgress(total: 1))

    var download: Download
    var task: NetworkSessionTask?

    let promise: Promise<Void>
    private let resolver: Resolver<Void>

    init(download: Download) {
        self.download = download
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
    private var cancellables: Set<AnyCancellable> = []

    let batchId: Int64
    let responses: [DownloadResponse]

    private let progressSubject = CurrentValueSubject<DownloadProgress, Never>(DownloadProgress(total: 1))

    public var progress: AnyPublisher<DownloadProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }

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

        responses.forEach { response in
            response.progressSubject
                .sink { [weak self] progress in
                    self?.updateResponsesProgress()
                }
                .store(in: &cancellables)
        }
    }

    private func updateResponsesProgress() {
        var accumulated: Double = 0
        for response in responses {
            accumulated += response.progressSubject.value.progress
        }
        updateProgress(completed: accumulated / Double(responses.count))
    }

    func updateProgress(total: Double? = nil, completed: Double? = nil) {
        var value = progressSubject.value
        value.total = total ?? value.total
        value.completed = completed ?? value.completed
        progressSubject.send(value)
    }

    public func cancel() async {
        if promise.isPending {
            do {
                try await cancellable?.cancel(batch: self)
            } catch {
                crasher.recordError(error, reason: "Failed to cancel batch download.")
            }
        }
    }

    func fulfill() {
        resolver.fulfill(())
    }

    func reject(_ error: Error) {
        resolver.reject(error)
    }
}
