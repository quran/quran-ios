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
import Utilities
import VLogging

func describe(_ task: NetworkSessionTask) -> String {
    "\(type(of: task))(\(task.taskIdentifier): " + ((task.originalRequest?.url?.absoluteString ?? task.currentRequest?.url?.absoluteString) ?? "") + ")"
}

actor DownloadBatchDataController {
    private let maxSimultaneousDownloads: Int
    private let persistence: DownloadsPersistence
    private var session: NetworkSession?

    private var runningDownloads: [Int: DownloadResponse] = [:]
    private var batches: Set<DownloadBatchResponse> = []

    init(maxSimultaneousDownloads: Int, persistence: DownloadsPersistence) {
        self.maxSimultaneousDownloads = maxSimultaneousDownloads
        self.persistence = persistence
    }

    func update(session: NetworkSession) {
        self.session = session
    }

    private var runningTasks: [DownloadResponse] {
        get async {
            await batches.flatMap(\.responses).asyncFilter { await $0.download.taskId != nil }
        }
    }

    private func searchForResponse(of task: NetworkSessionTask) async -> DownloadResponse? {
        for batch in batches {
            for response in batch.responses {
                if await response.download.taskId == task.taskIdentifier {
                    return response
                }
            }
        }
        return nil
    }

    func getOnGoingDownloads() -> [DownloadBatchResponse] {
        Array(batches)
    }

    func downloadResponse(for task: NetworkSessionTask) async -> DownloadResponse? {
        if let response = await searchForResponse(of: task) {
            if await response.task == nil {
                logger.info("Associating task \(task.taskIdentifier) with DownloadResponse")
                await response.setDownloading(task: task)
            }
            return response
        } else {
            return nil
        }
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

    private func createResponse(forBatch batch: DownloadBatch) async -> DownloadBatchResponse {
        var responses: [DownloadResponse] = []
        for download in batch.downloads {
            let response = DownloadResponse(download: download)

            // if it was saved as completed, then fulfill it
            if download.status == .completed {
                await response.fulfill()
            }
            responses.append(response)
        }

        // create batch response
        let response = await DownloadBatchResponse(batchId: batch.id, responses: responses)
        batches.insert(response)

        Task {
            await completeBatch(response)
        }

        return response
    }

    private func completeBatch(_ response: DownloadBatchResponse) async {
        do {
            try await response.completion()
        } catch {
            logger.error("Batch failed to download with error: \(error)")
        }

        // delete the completed response
        batches.remove(response)
        await run("DeleteBatch") { try await $0.delete(batchIds: [response.batchId]) }

        // Start pending tasks
        await startPendingTasksIfNeeded()
    }

    private var loadedInitialRunningTasks = false

    func setRunningTasks(_ tasks: [NetworkSessionDownloadTask]) async {
        let tasksById = Dictionary(uniqueKeysWithValues: tasks.map { ($0.taskIdentifier, $0) })
        for batch in batches {
            for response in batch.responses {
                if let savedTaskId = await response.download.taskId {
                    if let task = tasksById[savedTaskId] {
                        logger.info("Associating download with a task: \(describe(task))")
                        await response.setDownloading(task: task)
                    } else {
                        await response.setPending()
                        logger.info("Couldn't find task with id \(savedTaskId)")
                    }
                }
            }
        }

        loadedInitialRunningTasks = true

        // start pending tasks if needed
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
        guard runningTasks.count < maxSimultaneousDownloads else {
            return
        }
        // and there are things to download
        guard !batches.isEmpty else {
            return
        }

        await startDownloadTasks(session: session,
                                 maxNumberOfDownloads: maxSimultaneousDownloads - runningTasks.count)
    }

    private func startDownloadTasks(session: NetworkSession, maxNumberOfDownloads: Int) async {
        // Sort the batches by id.
        let batches = batches.sorted { $0.batchId < $1.batchId }

        var downloadTasks: [(task: NetworkSessionDownloadTask, response: DownloadResponse)] = []
        for batch in batches {
            for response in batch.responses {
                if downloadTasks.count >= maxNumberOfDownloads { // Max download channels?
                    break
                }
                if let task = await response.downloadIfPending(session: session) {
                    await updateDownloadPersistence(response)
                    task.resume()
                    downloadTasks.append((task, response))
                }
            }
        }

        if downloadTasks.isEmpty {
            return
        }

        logger.info("Enqueuing \(downloadTasks.count) to download on empty channels.")

        // Update the newly downloading tasks.
        await run("UpdateDownloads") {
            try await $0.update(downloads: downloadTasks.asyncMap { await $0.response.download })
        }

        // start the tasks
        for download in downloadTasks {
            download.task.resume()
        }
    }

    func downloadCompleted(_ response: DownloadResponse) async {
        await response.fulfill()
        await updateDownloadPersistence(response)

        // start pending tasks if needed
        await startPendingTasksIfNeeded()
    }

    func downloadFailed(_ response: DownloadResponse, with error: Error) async {
        await response.reject(error)

        // start pending tasks if needed
        await startPendingTasksIfNeeded()
    }

    private func updateDownloadPersistence(_ response: DownloadResponse) async {
        await run("UpdateDownload") {
            try await $0.update(downloads: [await response.download])
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
