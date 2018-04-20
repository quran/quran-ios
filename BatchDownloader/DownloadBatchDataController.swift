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
import VFoundation

func describe(_ task: URLSessionTask) -> String {
    return "\(task.taskIdentifier) " + ((task.originalRequest?.url?.absoluteString ?? task.currentRequest?.url?.absoluteString) ?? "")
}

class DownloadBatchDataController {
    private let maxSimultaneousDownloads: Int
    private let persistence: DownloadsPersistence

    var session: URLSession?
    weak var cancellable: NetworkResponseCancellable?

    private var runningDownloads: [Int: DownloadResponse] = [:]
    private var batchesByIds: [Int64: DownloadBatchResponse] = [:]

    init(maxSimultaneousDownloads: Int, persistence: DownloadsPersistence) {
        self.maxSimultaneousDownloads = maxSimultaneousDownloads
        self.persistence = persistence
    }

    func getOnGoingDownloads() -> [Int64: DownloadBatchResponse] {
        // make sure we set the cancellable
        // as we could load the requests before the cancellable is set
        for (_, batch) in batchesByIds {
            batch.cancellable = cancellable
        }
        return batchesByIds
    }

    func downloadResponse(for task: URLSessionTask) -> DownloadResponse? {
        // get from running
        if let response = runningDownloads[task.taskIdentifier] {
            return response
        }

        // get from pending
        CLog("Didn't find a running task", describe(task), "will search in pending tasks")
        for (_, batch) in batchesByIds {
            for response in batch.responses where response.download.taskId == task.taskIdentifier {
                CLog("Found task in pending tasks")
                runningDownloads[task.taskIdentifier] = response
                response.task = task
                return response
            }
        }
        CLog("Didn't find the task in pending tasks")
        return nil
    }

    func download(_ batchRequest: DownloadBatchRequest) throws -> DownloadBatchResponse {
        CLog("Batching \(batchRequest.requests.count) to download.")
        // save to persistence
        let batch = try persistence.insert(batch: batchRequest)

        // create the response
        let response = createResponse(forBatch: batch)
        batchesByIds[batch.id] = response

        // start pending downloads if needed
        try startPendingTasksIfNeeded()

        return response
    }

    func loadBatchesFromPersistence() throws {
        let batches = try persistence.retrieveAll()
        CLog("Loading \(batches.count) from persistence")
        for batch in batches {
            let response = createResponse(forBatch: batch)
            batchesByIds[batch.id] = response
        }
    }

    private func createResponse(forBatch batch: DownloadBatch) -> DownloadBatchResponse {
        var responses: [DownloadResponse] = []
        for download in batch.downloads {
            // create the response
            let response = DownloadResponse(download: download, progress: QProgress(totalUnitCount: 1))

            response.promise.catch { _ in
                // ignore all errors
            }

            // if completed, then show that
            // if it is running, add it to running tasks
            if download.status == .completed {
                response.progress.completedUnitCount = 1
                response.fulfill(())
            } else if let taskId = download.taskId {
                runningDownloads[taskId] = response
            }
            responses.append(response)
        }

        // create batch response
        let response = DownloadBatchResponse(batchId: batch.id, responses: responses, cancellable: cancellable)
        return response
    }

    func setRunningTasks(_ tasks: [URLSessionTask]) throws {
        guard !tasks.isEmpty else {
            return
        }
        // load the models from persistence if not loaded yet
        if batchesByIds.isEmpty {
            try loadBatchesFromPersistence()
        }

        let previouslyDownloading = batchesByIds
            .flatMap { $1.responses }
            .filter { $0.download.taskId != nil }
            .flatGroup { $0.download.taskId ?? 0 }

        // associate tasks with downloads
        for task in tasks {
            if let response = previouslyDownloading[task.taskIdentifier] {
                runningDownloads[task.taskIdentifier] = response
                response.task = task

                CLog("Associating download with a DownloadTask:", describe(task))
            } else {
                CLog("Cancelling DownloadTask: ", describe(task))

                // cancel the task
                task.cancel()
            }
        }

        // remove downloads that doesn't have tasks from being running
        for (_, response) in previouslyDownloading where response.task == nil {
            response.download.taskId = nil // don't save it as it doesn't matter
            response.download.status = .pending

            CLog("From downloading to pending", response.download.request.url)
        }

        // start pending tasks if needed
        try startPendingTasksIfNeeded()
    }

    private func removeCompletedDownloadsAndNotify() throws {

        // complete fulfilled/rejected batches
        var batchesToDelete: [Int64] = []
        let batches = batchesByIds
        for (id, batch) in batches {
            var state = State.completed
            for response in batch.responses {
                if let error = response.promise.error {
                    state.fail(error)
                } else if response.promise.isPending {
                    state.bePending() // we won't break since we might have another one failed
                }
            }

            // if finished successfully or failed
            if state.isFinished {
                batchesByIds[id] = nil
                batchesToDelete.append(id)

                // if successful
                if state.isCompleted {
                    // fulfill it
                    batch.fulfill(())
                    CLog("Batch \(batch.batchId) completed successfully")
                } else if state.isFailed { // if failed

                    // cancel any on-going downloads
                    cancelOngoingResponses(for: batch)

                    // get the error if it is not cancelled
                    let cancelledError = URLError(.cancelled)
                    let error = state.errorOtherThan(cancelledError as NSError) ?? cancelledError
                    // reject it anyway
                    batch.reject(error)
                    CLog("Batch \(batch.batchId) rejected with error: \(error)")
                }
            }
        }

        if !batchesToDelete.isEmpty {
            // delete the completed batches
            try persistence.delete(batchIds: batchesToDelete)
        }
    }

    private func startPendingTasksIfNeeded() throws {
        // if we have a session
        guard let session = session else {
            return
        }
        // and there are empty slots to use for downloading
        guard  runningDownloads.count < maxSimultaneousDownloads else {
            return
        }
        // and there are things to download
        guard !batchesByIds.isEmpty else {
            return
        }

        let emptySlots = maxSimultaneousDownloads - runningDownloads.count

        // sort the batches by id
        let batches = batchesByIds.sorted { $0.key < $1.key }

        var downloads: [(task: URLSessionDownloadTask, response: DownloadResponse)] = []
        for (_, batch) in batches {
            for download in batch.responses {
                guard download.task == nil else {
                    continue
                }
                // create the download task
                let task = session.downloadTask(with: download.download.request)
                download.task = task
                download.download.taskId = task.taskIdentifier
                download.download.status = .downloading

                downloads.append((task, download))
                // if all slots are filled, exist
                if downloads.count >= emptySlots {
                    break
                }
            }
            // if all slots are filled, exist
            if downloads.count >= emptySlots {
                break
            }
        }

        // continue if there are data
        guard !downloads.isEmpty else {
            return
        }

        let message = "Enqueuing \(downloads.count) to download on empty channels."
        if downloads.count == 1 {
            CLog(message)
        } else {
            log(message)
        }

        // updated downloads
        do {
            try persistence.update(downloads: downloads.map { $0.response.download })
        } catch {
            // roll back
            for download in downloads {
                download.response.task = nil
                download.response.download.status = .pending
                download.response.download.taskId = nil
            }

            for download in downloads {
                download.task.cancel()
            }

            // rethrow
            throw error
        }

        // set them to be running
        for download in downloads {
            runningDownloads[download.task.taskIdentifier] = download.response
        }

        // start the tasks
        for download in downloads {
            download.task.resume()
        }
    }

    func downloadCompleted(_ response: DownloadResponse) throws {
        try update(response, to: .completed)
        // fulfill
        response.fulfill(())
        responseIsDone(response)

        // clean up the model
        try removeCompletedDownloadsAndNotify()

        // start pending tasks if needed
        try startPendingTasksIfNeeded()
    }

    func downloadFailed(_ response: DownloadResponse, with error: Error) throws {
        if response.promise.isPending {
            response.reject(error)
        }
        responseIsDone(response)

        // clean up the model
        try removeCompletedDownloadsAndNotify()

        // start pending tasks if needed
        try startPendingTasksIfNeeded()
    }

    func cancel(batch: DownloadBatchResponse) throws {
        // cancel any on-going downloads
        cancelOngoingResponses(for: batch)

        // clean up the model
        try removeCompletedDownloadsAndNotify()

        // start pending tasks if needed
        try startPendingTasksIfNeeded()
    }

    private func cancelOngoingResponses(for batch: DownloadBatchResponse) {
        for response in batch.responses {
            if response.promise.isPending {
                response.reject(URLError(.cancelled))
            }
            responseIsDone(response)
            response.task?.cancel()
        }
    }

    private func update(_ response: DownloadResponse, to status: Download.Status) throws {
        let oldStatus = response.download.status
        response.download.status = status
        do {
            try persistence.update(url: response.download.request.url, newStatus: status)
        } catch {
            // roll back
            response.download.status = oldStatus

            // rethrow
            throw error
        }
    }

    private func responseIsDone(_ response: DownloadResponse) {
        if let id = response.task?.taskIdentifier {
            runningDownloads[id] = nil
        }
    }
}

private enum State { case completed; case failed([Error]); case pending
    mutating func fail(_ error: Error) {
        switch self {
        case .failed(var errors):
            errors.append(error)
            self = .failed(errors)
        default: self = .failed([error])
        }
    }
    mutating func bePending() {
        switch self {
        case .completed: self = .pending
        default: break
        }
    }

    var isFinished: Bool {
        switch self {
        case .completed: return true
        case .failed: return true
        default: return false
        }
    }

    var isCompleted: Bool {
        switch self {
        case .completed: return true
        default: return false
        }
    }

    var isFailed: Bool {
        switch self {
        case .failed: return true
        default: return false
        }
    }

    func errorOtherThan(_ error: NSError) -> Error? {
        switch self {
        case .failed(let errors):
            for failedError in errors as [NSError] {
                if failedError.domain != error.domain || failedError.code == error.code {
                    return failedError
                }
            }
            return nil
        default: return nil
        }
    }
}
