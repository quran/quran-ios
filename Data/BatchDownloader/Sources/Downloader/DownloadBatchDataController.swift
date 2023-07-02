//
//  DownloadBatchDataController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/17.
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
import Foundation
import NetworkSupport
import Utilities
import VLogging

func describe(_ task: NetworkSessionTask) -> String {
    "\(type(of: task))(\(task.taskIdentifier): " + ((task.originalRequest?.url?.absoluteString ?? task.currentRequest?.url?.absoluteString) ?? "") + ")"
}

struct SingleTaskResponse {
    let request: DownloadRequest
    let response: DownloadBatchResponse
}

actor DownloadBatchDataController {
    // MARK: Lifecycle

    init(maxSimultaneousDownloads: Int, persistence: DownloadsPersistence) {
        self.maxSimultaneousDownloads = maxSimultaneousDownloads
        self.persistence = persistence
    }

    // MARK: Internal

    func update(session: NetworkSession) {
        self.session = session
    }

    func getOnGoingDownloads() -> [DownloadBatchResponse] {
        Array(batches)
    }

    func downloadRequestResponse(for task: NetworkSessionTask) async -> SingleTaskResponse? {
        for batch in batches {
            if let request = await batch.downloadRequest(for: task) {
                return SingleTaskResponse(request: request, response: batch)
            }
        }
        return nil
    }

    func download(_ batchRequest: DownloadBatchRequest) async throws -> DownloadBatchResponse {
        logger.info("Batching \(batchRequest.requests.count) to download.")
        // save to persistence
        let batch = try await persistence.insert(batch: batchRequest)

        // create the response
        let response = await createResponse(forBatch: batch)

        // start pending downloads if needed
        await startPendingTasksIfNeeded()

        return response
    }

    func loadBatchesFromPersistence() async throws {
        let batches = try await persistence.retrieveAll()
        logger.info("Loading \(batches.count) from persistence")
        for batch in batches {
            _ = await createResponse(forBatch: batch)
        }
    }

    func setRunningTasks(_ tasks: [NetworkSessionDownloadTask]) async {
        for batch in batches {
            await batch.associateTasks(tasks)
        }

        loadedInitialRunningTasks = true

        // start pending tasks if needed
        await startPendingTasksIfNeeded()
    }

    func downloadCompleted(_ response: SingleTaskResponse) async {
        await response.response.complete(response.request, result: .success(()))
        await updateDownloadPersistence(response)

        // start pending tasks if needed
        await startPendingTasksIfNeeded()
    }

    func downloadFailed(_ response: SingleTaskResponse, with error: Error) async {
        await response.response.complete(response.request, result: .failure(error))

        // start pending tasks if needed
        await startPendingTasksIfNeeded()
    }

    // MARK: Private

    private let maxSimultaneousDownloads: Int
    private let persistence: DownloadsPersistence
    private weak var session: NetworkSession?

    private var batches: Set<DownloadBatchResponse> = []

    private var loadedInitialRunningTasks = false

    private var runningTasks: Int {
        get async {
            var count = 0
            for batch in batches {
                count += await batch.runningTasks
            }
            return count
        }
    }

    private static func completeBatch(_ response: DownloadBatchResponse) async {
        do {
            // Wait until sequence completes
            for try await _ in response.progress { }
        } catch {
            logger.error("Batch failed to download with error: \(error)")
        }
    }

    private func createResponse(forBatch batch: DownloadBatch) async -> DownloadBatchResponse {
        let response = await DownloadBatchResponse(batch: batch)
        batches.insert(response)

        Task { [weak self] in
            await Self.completeBatch(response)
            guard let self else {
                return
            }
            await cleanUpForCompletedBatch(response)
        }

        return response
    }

    private func cleanUpForCompletedBatch(_ response: DownloadBatchResponse) async {
        // delete the completed response
        batches.remove(response)
        await run("DeleteBatch") { try await $0.delete(batchIds: [response.batchId]) }

        // Start pending tasks
        await startPendingTasksIfNeeded()
    }

    private func startPendingTasksIfNeeded() async {
        if !loadedInitialRunningTasks {
            return
        }

        // if we have a session
        guard let session else {
            return
        }
        // and there are empty slots to use for downloading
        let runningTasks = await runningTasks
        guard runningTasks < maxSimultaneousDownloads else {
            return
        }
        // and there are things to download
        guard !batches.isEmpty else {
            return
        }

        await startDownloadTasks(
            session: session,
            maxNumberOfDownloads: maxSimultaneousDownloads - runningTasks
        )
    }

    private func startDownloadTasks(session: NetworkSession, maxNumberOfDownloads: Int) async {
        // Sort the batches by id.
        let batches = batches.sorted { $0.batchId < $1.batchId }

        var downloadTasks: [(task: NetworkSessionDownloadTask, response: SingleTaskResponse)] = []
        for batch in batches {
            while downloadTasks.count < maxNumberOfDownloads { // Max download channels?
                guard let (request, task) = await batch.startDownloadIfNeeded(session: session) else {
                    break
                }

                let response = SingleTaskResponse(request: request, response: batch)
                await updateDownloadPersistence(response)
                downloadTasks.append((task, response))
            }
        }

        if downloadTasks.isEmpty {
            return
        }

        logger.info("Enqueuing \(downloadTasks.count) to download on empty channels.")

        // start the tasks
        for download in downloadTasks {
            download.task.resume()
        }
    }

    private func updateDownloadPersistence(_ response: SingleTaskResponse) async {
        await run("UpdateDownload") {
            try await $0.update(downloads: [await response.response.download(of: response.request)])
        }
    }

    private func run(_ operation: String, _ body: (DownloadsPersistence) async throws -> Void) async {
        do {
            try await body(persistence)
        } catch {
            crasher.recordError(error, reason: "DownloadPersistence." + operation)
        }
    }
}
