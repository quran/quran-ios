//
//  DownloadManagerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-22.
//

import AsyncAlgorithms
import AsyncUtilitiesForTesting
@testable import BatchDownloader
import BatchDownloaderFake
import NetworkSupport
import NetworkSupportFake
import XCTest

final class DownloadManagerTests: XCTestCase {
    private let fileManager = FileManager.default
    private var downloader: DownloadManager!
    private var session: NetworkSessionFake?

    private let request1 = BatchDownloaderFake.makeDownloadRequest("1")
    private let request2 = BatchDownloaderFake.makeDownloadRequest("2")
    private let request3 = BatchDownloaderFake.makeDownloadRequest("3")
    private let request4 = BatchDownloaderFake.makeDownloadRequest("4")
    private let request5 = BatchDownloaderFake.makeDownloadRequest("5")

    override func setUp() async throws {
        try await super.setUp()
        (downloader, session) = await BatchDownloaderFake.makeDownloader()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        downloader = nil
        session = nil
        BatchDownloaderFake.tearDown()
    }

    @MainActor
    func testBackgroundSessionCompletionHandler() async {
        // assign a completion handler
        @MainActor
        class Calls {
            var calls = 0
            func increment() {
                calls += 1
            }
        }
        let calls = Calls()
        downloader.setBackgroundSessionCompletion { @Sendable @MainActor () in
            XCTAssertTrue(Thread.isMainThread)
            calls.increment()
        }

        // finish background events
        let channel = AsyncChannel<Void>()
        session?.finishBackgroundEvents(channel: channel)
        await channel.next()

        // verify completion handler called
        XCTAssertEqual(calls.calls, 1)
    }

    func testLoadingOnGoingDownload() async throws {
        let emptyDownloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(emptyDownloads.count, 0)

        let batch = DownloadBatchRequest(requests: [request1, request2])
        _ = try await downloader.download(batch)

        // keeping downloads in memory
        let memoryDownloads = await downloader.getOnGoingDownloads()
        let downloads = await downloadTasks(from: memoryDownloads)
        XCTAssertEqual(memoryDownloads.count, 1)
        XCTAssertEqual(downloads.count, 2)

        // deallocate downloader & create new one
        downloader = nil
        (downloader, session) = await BatchDownloaderFake.makeDownloader(downloads: downloads)

        // loaded downlodas from disk
        let diskDownloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(diskDownloads.count, 1)
        await AsyncAssertEqual(await downloadTasks(from: diskDownloads).count, 2)
    }

    func testDownloadBatchCompleted() async throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2])
        let response = try await downloader.download(batch)
        let responses = await response.responses
        XCTAssertEqual(responses.count, 2)

        let batchListener = await HistoryProgressListener(await response.progress)

        // complete the downloads
        let task1 = try await completeTask(response, i: 0)
        let task2 = try await completeTask(response, i: 1, totalBytes: 100, progressLoops: 2)

        // verify progress and promise result
        try await verifyCompletedTask(task: task1)
        try await verifyCompletedTask(task: task2)
        await AsyncAssertEqual(1.0, await batchListener.values.last)

        try await response.completion()
    }

    func testDownloadBatch1Success1Error1CancelOthers() async throws {
        // download a batch of 2 requests
        let batchRequest = DownloadBatchRequest(requests: [request1, request2, request3, request4, request5])
        let batch = try await downloader.download(batchRequest)
        let response = await batch.responses[1]

        // complete 1st download
        let task1 = try await completeTask(batch, i: 0)

        // fail 2nd download with no resume data
        let task2 = try await AsyncUnwrap(await response.task as? SessionTask)
        session?.failDownloadTask(task2, error: URLError(.timedOut))

        // verify promise result
        await AsyncAssertThrows(try await batch.completion(), NetworkError.serverNotReachable as NSError)

        // 1st task
        try await verifyCompletedTask(task: task1)

        // 2nd task
        await AsyncAssertThrows(try await response.completion(), NetworkError.serverNotReachable as NSError)
        await AsyncAssertEqual(await resumeURL(response: batch.responses[1]).isReachable, false)
        await AsyncAssertEqual(await destinationURL(response: batch.responses[1]).isReachable, false)

        // other tasks should be cancelled
        for i in 2 ..< batchRequest.requests.count {
            await AsyncAssertThrows(try await batch.responses[i].completion(), CancellationError() as NSError)
        }
    }

    func testDownloadFailWithResumeData() async throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)

        // fail download with resume data
        let task = try await AsyncUnwrap(await response.responses[0].task as? SessionTask)
        let resumeText = "some data"
        let error = URLError(.networkConnectionLost, userInfo: [
            NSURLSessionDownloadTaskResumeData: resumeText.data(using: .utf8) as Any,
        ])
        session?.failDownloadTask(task, error: error)

        // verify promise result
        await AsyncAssertThrows(try await response.completion(), NetworkError.connectionLost as NSError)

        // verify task
        await AsyncAssertThrows(try await response.responses[0].completion(), NetworkError.connectionLost as NSError)
        try await AsyncAssertEqual(try String(contentsOf: await resumeURL(response: await response.responses[0])), resumeText)
    }

    func testDownloadBatchAfterEnquingThem() async throws {
        // download a batch of 2 requests
        let request = DownloadBatchRequest(requests: [request1, request2, request3, request4])
        let response = try await downloader.download(request)

        actor BatchCompletion {
            var completed = false
            func complete() {
                completed = true
            }
        }

        let batchCompletion = BatchCompletion()
        Task {
            try? await response.completion()
            await batchCompletion.complete()
        }

        await AsyncAssertEqual(await response.responses[0].task != nil, true)
        await AsyncAssertEqual(await response.responses[1].task != nil, true)
        await AsyncAssertEqual(await response.responses[2].task != nil, true)
        await AsyncAssertEqual(await response.responses[3].task == nil, true)

        // complete tasks
        var tasks: [CompletedTask] = []
        for i in 0 ..< BatchDownloaderFake.maxSimultaneousDownloads {
            tasks.append(try await completeTask(response, i: i))
        }

        // assert the batch not completed but the others finished
        await AsyncAssertEqual(await batchCompletion.completed, false)
        await AsyncAssertEqual(await response.responses[3].isPending, true)
        for task in tasks {
            try await verifyCompletedTask(task: task)
        }

        // assert task started
        await AsyncAssertEqual(await response.responses[3].task != nil, true)

        // complete the pending task
        let lastTask = try await completeTask(response, i: 3)

        // assert the task completed
        try await response.completion()
        try await verifyCompletedTask(task: lastTask)
    }

    func testDownloadBatchAfterEnquingThemInWithDifferentSession() async throws {
        // start first session
        let batch = DownloadBatchRequest(requests: [request1, request2, request3])
        let memoryResponse = try await downloader.download(batch)

        // get the tasks to pass them to the next session
        let memoryDownloads = await downloader.getOnGoingDownloads()
        let downloads = await downloadTasks(from: memoryDownloads)

        // complete first task in the first session
        let task1 = try await completeTask(memoryResponse, i: 0)

        // deallocate downloader & create new one
        downloader = nil
        session = nil
        (downloader, session) = await BatchDownloaderFake.makeDownloader(downloads: downloads)

        let diskDownloads = await downloader.getOnGoingDownloads()
        let diskResponse = try XCTUnwrap(diskDownloads.first)

        // wait for the queue to finish so the session is initialized
        wait(for: try XCTUnwrap(session?.delegateQueue.underlyingQueue))

        let task2 = try await completeTask(diskResponse, i: 1)
        let task3 = try await completeTask(diskResponse, i: 2)

        // assert the response & tasks completed
        try await diskResponse.completion()
        try await verifyCompletedTask(task: task1)
        try await verifyCompletedTask(task: task2)
        try await verifyCompletedTask(task: task3)
    }

    func testDownloadBatchCancelled() async throws {
        // download a batch of 2 requests, then cancel it
        let batch = DownloadBatchRequest(requests: [request1, request2])
        let response = try await downloader.download(batch)
        // cancel
        await response.cancel()

        // wait until response is cancelled
        try? await response.completion()
        await Task.megaYield()

        // verify response is cancelled
        let downloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(downloads.count, 0)

        // other tasks should be cancelled as well
        for taskResponse in await response.responses {
            await AsyncAssertThrows(try await taskResponse.completion(), CancellationError() as NSError)
        }
    }

    private func completeTask(_ batch: DownloadBatchResponse,
                              i: Int,
                              totalBytes: Int = 100,
                              progressLoops: Int = 4,
                              file: StaticString = #filePath,
                              line: UInt = #line) async throws -> CompletedTask
    {
        let response = await batch.responses[i]
        let task = try await AsyncUnwrap(await response.task as? SessionTask, file: file, line: line)
        let text = Int.random(in: 0 ..< Int.max).description
        let source = try BatchDownloaderFake.createTextFile(at: "loc-\(i).txt", content: text)
        let destination = await destinationURL(response: response)
        XCTAssertTrue(source.isReachable, file: file, line: line)
        let listener = await HistoryProgressListener(await response.progress)
        await session?.completeDownloadTask(task, location: source, totalBytes: totalBytes, progressLoops: progressLoops)
        return CompletedTask(task: task,
                             text: text,
                             source: source,
                             destination: destination,
                             progressLoops: progressLoops,
                             listener: listener,
                             response: response)
    }

    private func verifyCompletedTask(task: CompletedTask, file: StaticString = #filePath, line: UInt = #line) async throws {
        var progressValues: [Double] = []
        for i in 0 ..< (task.progressLoops + 1) {
            progressValues.append(1 / Double(task.progressLoops) * Double(i))
        }
        await AsyncAssertEqual(progressValues, await task.listener.values, file: file, line: line)
        try await task.response.completion()

        // verify downloads saved
        XCTAssertFalse(task.source.isReachable, file: file, line: line)
        XCTAssertEqual(try String(contentsOf: task.destination), task.text, file: file, line: line)
    }

    private func downloadTasks(from batches: [DownloadBatchResponse]) async -> [SessionTask] {
        var tasks = [SessionTask]()
        for batch in batches {
            for response in await batch.responses {
                if let task = await response.task as? SessionTask {
                    tasks.append(task)
                }
            }
        }
        return tasks
    }

    private func resumeURL(response: DownloadResponse) async -> URL {
        FileManager.documentsURL.appendingPathComponent(await response.download.request.resumePath)
    }

    private func destinationURL(response: DownloadResponse) async -> URL {
        FileManager.documentsURL.appendingPathComponent(await response.download.request.destinationPath)
    }

    private struct CompletedTask {
        let task: SessionTask
        let text: String
        let source: URL
        let destination: URL
        let progressLoops: Int
        let listener: HistoryProgressListener
        let response: DownloadResponse
    }
}
