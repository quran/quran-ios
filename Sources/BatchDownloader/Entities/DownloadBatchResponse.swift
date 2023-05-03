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

import AsyncExtensions
import Crashing
import Foundation
import Utilities

actor DownloadResponse {
    private(set) var download: Download
    private(set) var task: NetworkSessionTask?

    private let continuations = MulticastContinuation<Void, Error>()

    var isPending: Bool {
        get async {
            await continuations.isPending
        }
    }

    init(download: Download) {
        self.download = download
    }

    private let progressSubject = AsyncCurrentValueSubject(DownloadProgress(total: 1))
    var progress: OpaqueAsyncSequence<AsyncCurrentValueSubject<DownloadProgress>> {
        progressSubject.eraseToOpaqueAsyncSequence()
    }

    var currentProgress: DownloadProgress { progressSubject.value }

    func updateProgress(_ progress: DownloadProgress) async {
        if await isPending {
            progressSubject.send(progress)
        }
    }

    func setDownloading(task: NetworkSessionTask) async {
        assert(self.task == nil, "Cannot set task twice")
        if await continuations.isPending {
            self.task = task
            download.taskId = task.taskIdentifier
            download.status = .downloading
        }
    }

    func setPending() async {
        if await continuations.isPending {
            task = nil
            download.taskId = nil
            download.status = .pending
        }
    }

    func completion() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                await self.continuations.addContinuation(continuation)
            }
        }
    }

    func fulfill() async {
        if await continuations.isPending {
            download.status = .completed
            task = nil
            download.taskId = nil
            await continuations.resume(returning: ())
            progressSubject.send(.finished)
        }
    }

    func reject(_ error: Error) async {
        if await continuations.isPending {
            task = nil
            download.taskId = nil
            await continuations.resume(throwing: error)
        }
    }

    func cancel() async {
        if await continuations.isPending {
            await reject(CancellationError())
            task?.cancel()
        }
    }
}

public actor DownloadBatchResponse {
    let batchId: Int64
    let responses: [DownloadResponse]

    private let progressSubject = AsyncCurrentValueSubject(DownloadProgress(total: 1))
    public var progress: OpaqueAsyncSequence<AsyncCurrentValueSubject<DownloadProgress>> {
        progressSubject.eraseToOpaqueAsyncSequence()
    }

    private var completionTask: Task<Void, Error>?

    public var requests: [DownloadRequest] {
        get async {
            await responses.asyncMap { await $0.download.request }
        }
    }

    init(batchId: Int64, responses: [DownloadResponse]) async {
        self.batchId = batchId
        self.responses = responses

        let progressTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for response in responses {
                    group.addTask { [weak self] in
                        for await _ in await response.progress {
                            await self?.updateResponsesProgress()
                        }
                    }
                }
            }
        }

        completionTask = Task {
            try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                defer {
                    // Stop progress resporting, when task completes.
                    progressSubject.send(.finished)
                    progressTask.cancel()
                }

                for response in responses {
                    taskGroup.addTask {
                        try await response.completion()
                    }
                }

                do {
                    while try await taskGroup.next() != nil {
                        // execute until it completes or throw an error
                    }
                } catch {
                    // Cancel other tasks if any has failed
                    for response in responses {
                        await response.cancel()
                    }
                    // rethrow
                    crasher.recordError(error, reason: "Download failed \(batchId)")
                    throw error
                }
            }
        }
    }

    private func updateResponsesProgress() async {
        var accumulated: Double = 0
        for response in responses {
            accumulated += await response.currentProgress.progress
        }
        await updateProgress(completed: accumulated / Double(responses.count))
    }

    func updateProgress(total: Double? = nil, completed: Double? = nil) async {
        var value = progressSubject.value
        value.total = total ?? value.total
        value.completed = completed ?? value.completed
        progressSubject.send(value)
    }

    public func cancel() async {
        completionTask?.cancel()
        for response in responses {
            await response.cancel()
        }
    }

    public func completion() async throws {
        try await completionTask?.value
    }
}

extension DownloadBatchResponse: Hashable {
    public static func == (lhs: DownloadBatchResponse, rhs: DownloadBatchResponse) -> Bool {
        lhs.batchId == rhs.batchId
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(batchId)
    }
}
