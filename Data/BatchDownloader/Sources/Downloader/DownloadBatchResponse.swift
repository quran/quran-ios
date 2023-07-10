//
//  DownloadBatchResponse.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import Combine
import Crashing
import Foundation
import NetworkSupport
import Utilities
import VLogging

public typealias AsyncThrowingPublisher = Utilities.AsyncThrowingPublisher

private struct ResponseData {
    enum State {
        case finished
        case failed(Error)
        case inProgress
    }

    // MARK: Internal

    let progress = CurrentValueSubject<DownloadProgress, Error>(DownloadProgress(total: 1))
    let request: DownloadRequest
    var state: State

    // taskId != nil && task == nil means the task was executing in the background.
    // taskId == nil && task != nil cannot happen
    var taskId: Int?
    var task: NetworkSessionTask?

    var isInProgress: Bool {
        switch state {
        case .inProgress: return true
        case .finished, .failed: return false
        }
    }

    var finished: Bool {
        switch state {
        case .finished: return true
        case .inProgress, .failed: return false
        }
    }

    var failed: Bool {
        switch state {
        case .failed: return true
        case .inProgress, .finished: return false
        }
    }

    func download(batchId: Int64) -> Download {
        Download(taskId: taskId, request: request, status: isInProgress ? .downloading : .completed, batchId: batchId)
    }
}

public actor DownloadBatchResponse {
    // MARK: Lifecycle

    init(batch: DownloadBatch) async {
        batchId = batch.id
        requests = batch.downloads.map(\.request)

        for download in batch.downloads {
            let request = download.request
            let state: ResponseData.State
            switch download.status {
            case .completed:
                state = .finished
            case .downloading:
                state = .inProgress
            }
            responses[request] = ResponseData(request: request, state: state, taskId: download.taskId, task: nil)
        }

        for download in batch.downloads {
            // if it was saved as completed, then fulfill it
            if download.status == .completed {
                complete(download.request, result: .success(()))
            }
        }
    }

    // MARK: Public

    public nonisolated let requests: [DownloadRequest]

    public nonisolated var progress: AsyncThrowingPublisher<DownloadProgress> {
        progressSubject.values(bufferingPolicy: .bufferingNewest(1))
    }

    // TODO: Remove
    public nonisolated var currentProgress: DownloadProgress {
        progressSubject.value
    }

    public func cancel() async {
        await withTaskGroup(of: Void.self) { group in
            for request in requests {
                group.addTask {
                    await self.cancel(request)
                }
            }
        }
    }

    // MARK: Internal

    let batchId: Int64

    var runningTasks: Int {
        responses.values.filter { $0.isInProgress && $0.taskId != nil }.count
    }

    func associateTasks(_ tasks: [NetworkSessionDownloadTask]) {
        let tasksById = Dictionary(uniqueKeysWithValues: tasks.map { ($0.taskIdentifier, $0) })
        for request in responses.keys {
            mutableResponse(of: request) { response in
                if let savedTaskId = response.taskId {
                    if let task = tasksById[savedTaskId] {
                        logger.info("Associating download with a task: \(describe(task))")
                        response.task = task
                    } else {
                        response.taskId = nil
                        if !response.finished {
                            logger.error("Couldn't find task with id \(savedTaskId)")
                        }
                    }
                }
            }
        }
    }

    func downloadRequest(for task: NetworkSessionTask) -> DownloadRequest? {
        if let request = responses.values.first(where: { $0.taskId == task.taskIdentifier })?.request {
            mutableResponse(of: request) { response in
                if response.task == nil {
                    logger.info("Associating task \(task.taskIdentifier) with DownloadResponse")
                    response.task = task
                }
            }
            return request
        }
        return nil
    }

    func updateProgress(of request: DownloadRequest, _ progress: DownloadProgress) {
        if completed {
            return
        }

        mutableResponse(of: request) { response in
            response.state = .inProgress
            response.progress.send(progress)
        }

        let accumulated = responses.values.map(\.progress.value.progress).reduce(0, +)
        let overallProgress = DownloadProgress(total: 1, completed: accumulated / Double(responses.count))
        progressSubject.send(overallProgress)
    }

    func complete(_ request: DownloadRequest, result: Result<Void, Error>) {
        let completedPreviously = completed

        let newState = { () -> ResponseData.State in
            switch result {
            case .success: return .finished
            case .failure(let error): return .failed(error)
            }
        }

        let completion = { () -> Subscribers.Completion<Error> in
            switch result {
            case .success: return .finished
            case .failure(let error): return .failure(error)
            }
        }

        mutableResponse(of: request) { response in
            response.state = newState()
            response.progress.send(DownloadProgress(total: 1, completed: 1))
            response.progress.send(completion: completion())
        }

        // if the overall request was just completed now
        guard completed && !completedPreviously else {
            return
        }

        if let error = firstError {
            crasher.recordError(error, reason: "Download failed \(batchId)")

            // Cancel other tasks if any has failed
            for request in requests {
                cancel(request)
            }

            progressSubject.send(completion: .failure(error))
        } else {
            progressSubject.send(completion: .finished)
        }
    }

    func download(of request: DownloadRequest) -> Download {
        let response = response(of: request)
        return response.download(batchId: batchId)
    }

    func startDownloadIfNeeded(session: NetworkSession) -> (DownloadRequest, NetworkSessionDownloadTask)? {
        guard let notStartedRequest = responses.values.first(where: { $0.isInProgress && $0.taskId == nil })?.request else {
            return nil
        }

        let task = session.downloadTask(with: notStartedRequest)

        mutableResponse(of: notStartedRequest) { response in
            response.taskId = task.taskIdentifier
            response.task = task
        }

        return (notStartedRequest, task)
    }

    // MARK: - Testing

    func details(of request: DownloadRequest) -> (task: NetworkSessionTask?, progress: CurrentValueSubject<DownloadProgress, Error>) {
        let response = response(of: request)
        return (response.task, response.progress)
    }

    // MARK: Private

    private nonisolated let progressSubject = CurrentValueSubject<DownloadProgress, Error>(DownloadProgress(total: 1))
    private var responses: [DownloadRequest: ResponseData] = [:]

    private var completed: Bool {
        if responses.values.contains(where: \.failed) {
            return true
        }
        return responses.values.allSatisfy(\.finished)
    }

    private var firstError: Error? {
        for response in responses.values {
            switch response.state {
            case .failed(let error): return error
            case .finished, .inProgress: continue
            }
        }
        return nil
    }

    private func progress(of request: DownloadRequest) -> AnyPublisher<DownloadProgress, Error> {
        let response = response(of: request)
        return response.progress.eraseToAnyPublisher()
    }

    private func cancel(_ request: DownloadRequest) {
        let response = response(of: request)
        response.task?.cancel()
        if let task = response.task {
            print("Cancelling task \(describe(task))")
        }
        complete(request, result: .failure(CancellationError()))
    }

    private func response(of request: DownloadRequest) -> ResponseData {
        if let response = responses[request] {
            return response
        } else {
            fatalError("DownloadRequest \(request) has no associated response")
        }
    }

    private func mutableResponse(of request: DownloadRequest, operation: (inout ResponseData) -> Void) {
        var response = response(of: request)
        operation(&response)
        responses[request] = response
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
