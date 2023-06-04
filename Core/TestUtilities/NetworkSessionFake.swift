//
//  NetworkSessionFake.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import AsyncAlgorithms
@testable import BatchDownloader
import Foundation
import NetworkSupport
import XCTest

public final class NetworkSessionFake: NetworkSession, @unchecked Sendable {
    public let delegateQueue: OperationQueue
    let delegate: NetworkSessionDelegate?
    public var downloads: [SessionTask] = []
    public var dataTasks: [SessionTask] = []

    public var dataResults: [URL: Result<Data, Error>] = [:]

    private var taskIdentifierCounter = 0
    private var taskIdentifier: Int {
        let temp = taskIdentifierCounter
        taskIdentifierCounter += 1
        return temp
    }

    public init(queue: OperationQueue, delegate: NetworkSessionDelegate? = nil, downloads: [SessionTask] = []) {
        delegateQueue = queue
        self.delegate = delegate
        self.downloads = downloads
    }

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
            await delegate?.networkSession(self,
                                           downloadTask: task,
                                           didWriteData: step,
                                           totalBytesWritten: written,
                                           totalBytesExpectedToWrite: Int64(totalBytes))
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

    func cancelTask(_ task: SessionTask) {
        delegateQueue.addOperation {
            Task {
                await self.delegate?.networkSession(self, task: task, didCompleteWithError: URLError(.cancelled))
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

    public func completeResponse(_ batch: DownloadBatchResponse,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) async throws
    {
        for (i, response) in await batch.responses.enumerated() {
            let task = try await AsyncUnwrap(await response.task as? SessionTask, file: file, line: line)
            let text = Int.random(in: 0 ..< Int.max).description
            let source = try Self.createTextFile(at: "loc-\(i).txt", content: text)
            XCTAssertTrue(source.isReachable, file: file, line: line)
            await completeDownloadTask(task, location: source, totalBytes: 10, progressLoops: 1)
        }
    }
}

public final class SessionTask: NetworkSessionDownloadTask, NetworkSessionDataTask, Hashable, @unchecked Sendable {
    public let taskIdentifier: Int
    public var originalRequest: URLRequest?
    public var currentRequest: URLRequest?
    public var response: URLResponse?
    var resumeData: Data?

    public var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?

    weak var session: NetworkSessionFake?

    init(taskIdentifier: Int) {
        self.taskIdentifier = taskIdentifier
    }

    var isCancelled = false

    public func cancel() {
        isCancelled = true
        session?.cancelTask(self)
    }

    public func resume() {
        isCancelled = false
    }

    public static func == (lhs: SessionTask, rhs: SessionTask) -> Bool {
        lhs.taskIdentifier == rhs.taskIdentifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(taskIdentifier)
    }
}

extension NetworkSessionFake {
    public static let maxSimultaneousDownloads = 3
    private static let downloads = "downloads"
    public static let downloadsURL = FileManager.documentsURL.appendingPathComponent(downloads)

    public static func makeDownloader(downloads: [SessionTask] = []) async -> (DownloadManager, NetworkSessionFake) {
        try? FileManager.default.createDirectory(at: NetworkSessionFake.downloadsURL, withIntermediateDirectories: true)
        let downloadsDBURL = Self.downloadsURL.appendingPathComponent("ongoing-downloads.db")

        let persistence = GRDBDownloadsPersistence(fileURL: downloadsDBURL)
        var session: NetworkSessionFake!
        let downloader = await DownloadManager(
            maxSimultaneousDownloads: maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: downloads)
                return session
            },
            persistence: persistence
        )
        return (downloader, session)
    }

    public static func tearDown() {
        try? FileManager.default.removeItem(at: NetworkSessionFake.downloadsURL)
    }

    public static func makeDownloadRequest(_ id: String) -> DownloadRequest {
        DownloadRequest(url: URL(validURL: "http://request/\(id)"), destinationPath: NetworkSessionFake.downloads + "/\(id).txt")
    }

    public static func createTextFile(at path: String, content: String) throws -> URL {
        let directory = NetworkSessionFake.downloadsURL.appendingPathComponent("temp")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(path)
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }
}
