//
//  NetworkSessionFake.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import AsyncAlgorithms
import AsyncUtilitiesForTesting
import Foundation
import NetworkSupport

public final class NetworkSessionFake: NetworkSession, @unchecked Sendable {
    // MARK: Lifecycle

    public init(queue: OperationQueue, delegate: NetworkSessionDelegate? = nil, downloads: [SessionTask] = []) {
        delegateQueue = queue
        self.delegate = delegate
        self.downloads = downloads
    }

    // MARK: Public

    public let delegateQueue: OperationQueue
    public var downloads: [SessionTask] = []
    public var dataTasks: [SessionTask] = []
    public var downloadsObserver: AsyncChannel<SessionTask>?

    public var dataResults: [URL: Result<Data, Error>] = [:]

    public func tasks() async -> ([NetworkSessionDataTask], [NetworkSessionUploadTask], [NetworkSessionDownloadTask]) {
        ([], [], downloads)
    }

    public func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask {
        let task = SessionTask(taskIdentifier: taskIdentifier)
        downloads.append(task)
        task.resumeData = resumeData
        return task
    }

    public func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask {
        let task = SessionTask(taskIdentifier: taskIdentifier)
        task.originalRequest = request
        downloads.append(task)
        Task { await downloadsObserver?.send(task) }
        return task
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let result = dataResults[request.url!] ?? .success(Data())
        let data = try result.get()
        return (data, URLResponse())
    }

    public func completeDownloadTask(_ task: SessionTask, location: URL, totalBytes: Int, progressLoops: Int) async {
        let step = Int64(1 / Double(progressLoops) * Double(totalBytes))
        for i in 0 ... progressLoops {
            let written = Int64(Double(i) / Double(progressLoops) * Double(totalBytes))
            await delegate?.networkSession(
                self,
                downloadTask: task,
                didWriteData: step,
                totalBytesWritten: written,
                totalBytesExpectedToWrite: Int64(totalBytes)
            )
            await Task.megaYield()
        }

        task.response = HTTPURLResponse(url: task.originalRequest!.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
        await delegate?.networkSession(self, downloadTask: task, didFinishDownloadingTo: location)
        await delegate?.networkSession(self, task: task, didCompleteWithError: nil)
        downloads = downloads.filter { $0 == task }
    }

    public func failDownloadTask(_ task: SessionTask, error: Error) {
        delegateQueue.addOperation {
            Task {
                await self.delegate?.networkSession(self, task: task, didCompleteWithError: error)
            }
        }
    }

    public func finishBackgroundEvents(channel: AsyncChannel<Void>) {
        delegateQueue.addOperation {
            Task {
                await self.delegate?.networkSessionDidFinishEvents(forBackgroundURLSession: self)
                await channel.send(())
            }
        }
    }

    // MARK: Internal

    let delegate: NetworkSessionDelegate?

    func cancelTask(_ task: SessionTask) {
        delegateQueue.addOperation {
            Task {
                await self.delegate?.networkSession(self, task: task, didCompleteWithError: URLError(.cancelled))
            }
        }
    }

    // MARK: Private

    private var taskIdentifierCounter = 0

    private var taskIdentifier: Int {
        let temp = taskIdentifierCounter
        taskIdentifierCounter += 1
        return temp
    }
}

public final class SessionTask: NetworkSessionDownloadTask, NetworkSessionDataTask, Hashable, @unchecked Sendable {
    // MARK: Lifecycle

    init(taskIdentifier: Int) {
        self.taskIdentifier = taskIdentifier
    }

    // MARK: Public

    public let taskIdentifier: Int
    public var originalRequest: URLRequest?
    public var currentRequest: URLRequest?
    public var response: URLResponse?
    public var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?

    public var isCancelled = false

    public static func == (lhs: SessionTask, rhs: SessionTask) -> Bool {
        lhs.taskIdentifier == rhs.taskIdentifier
    }

    public func cancel() {
        isCancelled = true
        session?.cancelTask(self)
    }

    public func resume() {
        isCancelled = false
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(taskIdentifier)
    }

    // MARK: Internal

    var resumeData: Data?

    weak var session: NetworkSessionFake?
}
