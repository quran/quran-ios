//
//  LastPageUpdater.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/10/16.
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

import Crashing
import QuranAnnotations
import QuranKit

@MainActor
public final class LastPageUpdater {
    private struct Request {
        let generation: UInt
        let page: Page
        let shouldWriteUnchangedPage: Bool
    }

    private struct Operation {
        let generation: UInt
        let page: Page
        let lastPage: LastPage?
    }

    // MARK: Lifecycle

    public init(service: any LastPageService) {
        let (requests, continuation) = AsyncStream.makeStream(
            of: Request.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        self.service = service
        requestContinuation = continuation
        startWorker(consuming: requests)
    }

    deinit {
        workerTask?.cancel()
        requestContinuation.finish()
    }

    // MARK: Public

    public private(set) var lastPage: LastPage?

    public func configure(initialPage: Page, lastPage: LastPage?) {
        generation &+= 1
        self.lastPage = lastPage
        enqueue(page: initialPage, shouldWriteUnchangedPage: true)
    }

    public func updateTo(pages: [Page]) {
        guard let page = pages.min() else {
            return
        }
        enqueue(page: page, shouldWriteUnchangedPage: false)
    }

    // MARK: Private

    private let service: any LastPageService
    private let requestContinuation: AsyncStream<Request>.Continuation
    private var generation: UInt = 0
    private var workerTask: Task<Void, Never>?

    private func enqueue(page: Page, shouldWriteUnchangedPage: Bool) {
        let request = Request(
            generation: generation,
            page: page,
            shouldWriteUnchangedPage: shouldWriteUnchangedPage
        )
        let result = requestContinuation.yield(request)
        guard case .dropped(let previousRequest) = result,
              previousRequest.generation == request.generation,
              previousRequest.page == request.page,
              previousRequest.shouldWriteUnchangedPage
        else {
            return
        }

        requestContinuation.yield(Request(
            generation: request.generation,
            page: request.page,
            shouldWriteUnchangedPage: true
        ))
    }

    private func startWorker(consuming requests: AsyncStream<Request>) {
        let service = service
        workerTask = Task { [weak self] in
            for await request in requests {
                guard !Task.isCancelled else { return }
                guard let operation = self?.makeOperation(for: request) else { continue }

                let result: Result<LastPage, Error>
                do {
                    if let lastPage = operation.lastPage {
                        result = .success(try await service.update(lastPage: lastPage, toPage: operation.page))
                    } else {
                        result = .success(try await service.add(page: operation.page))
                    }
                } catch {
                    result = .failure(error)
                }

                guard let self else { return }
                finish(operation, with: result)
            }
        }
    }

    private func makeOperation(for request: Request) -> Operation? {
        guard request.generation == generation else { return nil }
        guard request.shouldWriteUnchangedPage || request.page != lastPage?.page else { return nil }
        return Operation(generation: request.generation, page: request.page, lastPage: lastPage)
    }

    private func finish(_ operation: Operation, with result: Result<LastPage, Error>) {
        guard operation.generation == generation else { return }

        switch result {
        case .success(let lastPage):
            self.lastPage = lastPage
        case .failure(let error):
            guard !(error is CancellationError) else { return }
            let reason = operation.lastPage == nil
                ? "Failed to create a last page"
                : "Failed to update last page"
            crasher.recordError(error, reason: reason)
        }
    }
}
