//
//  DownloadManagerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-22.
//

import AsyncAlgorithms
import AsyncUtilitiesForTesting
import BatchDownloaderFake
import Combine
import NetworkSupport
import NetworkSupportFake
import Utilities
import XCTest
@testable import BatchDownloader

private typealias AsyncThrowingPublisher = Utilities.AsyncThrowingPublisher

final class DownloadManagerTests: XCTestCase {
    private struct CompletedTask {
        let task: SessionTask
        let text: String
        let source: URL
        let destination: RelativeFilePath
        let progressLoops: Int
        let listener: HistoryProgressListener
        let progress: CurrentValueSubject<DownloadProgress, Error>
    }

    // MARK: Internal

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
        downloader.setBackgroundSessionCompletion { @Sendable @MainActor in
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

    func test_onGoingDownloads_whileStartNotFinished() async throws {
        // Load a single batch
        let batch = DownloadBatchRequest(requests: [request1])
        _ = try await downloader.download(batch)

        // Deallocate downloader & create new one
        downloader = nil
        downloader = await BatchDownloaderFake.makeDownloaderDontWaitForSession()

        // Test calling getOnGoingDownloads and start at the same time.
        async let startTask: () = await downloader.start()
        async let downloadsTask = await downloader.getOnGoingDownloads()
        let (downloads, _) = await (downloadsTask, startTask)

        // Verify
        XCTAssertEqual(downloads.count, 1)
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
        let requests = response.requests
        XCTAssertEqual(requests, [request1, request2])

        let batchListener = await HistoryProgressListener(response.progress)

        // complete the downloads
        let task1 = try await completeTask(response, i: 0)
        let task2 = try await completeTask(response, i: 1, totalBytes: 100, progressLoops: 2)

        // verify progress and promise result
        try await verifyCompletedTask(task: task1)
        try await verifyCompletedTask(task: task2)
        await AsyncAssertEqual(1.0, await batchListener.values.last)

        for try await _ in response.progress { }
    }

    func testCancelDownloadsRemovesBatches() async throws {
        let batch = DownloadBatchRequest(requests: [request1, request2])
        _ = try await downloader.download(batch)

        let downloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(downloads.count, 1)

        await downloader.cancel(downloads: downloads)

        let remaining = await downloader.getOnGoingDownloads()
        XCTAssertEqual(remaining.count, 0)
    }

    @MainActor
    func testDownloadBatch1Success1Error1CancelOthers() async throws {
        // download a batch of 2 requests
        let batchRequest = DownloadBatchRequest(requests: [request1, request2, request3, request4, request5])
        let batch = try await downloader.download(batchRequest)
        let startedRequests = await batch.requests.asyncFilter { await batch.details(of: $0).task != nil }
        let requestToComplete = startedRequests[0]
        let requestToFail = startedRequests[1]
        let responseToFail = await batch.details(of: requestToFail)

        // complete 1st download
        let task1 = try await completeTask(batch, request: requestToComplete)

        // fail 2nd download with no resume data
        let task2 = try XCTUnwrap(responseToFail.task as? SessionTask)
        session?.failDownloadTask(task2, error: URLError(.timedOut))

        // verify overall result
        await assertThrows(batch.progress, NetworkError.serverNotReachable)

        // 1st task
        try await verifyCompletedTask(task: task1)

        // 2nd task
        await assertThrows(responseToFail.progress.values(), NetworkError.serverNotReachable)
        await AsyncAssertEqual(requestToFail.resumePath.isReachable, false)
        await AsyncAssertEqual(requestToFail.destination.isReachable, false)

        // other tasks should be cancelled
        for request in batch.requests.filter({ !startedRequests.contains($0) }) {
            let progress = await batch.details(of: request).progress.values()
            await assertThrows(progress, CancellationError())
        }
    }

    func testDownloadFailWithResumeData() async throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        // fail download with resume data
        let task = try XCTUnwrap(details.task as? SessionTask)
        let resumeText = "some data"
        let error = URLError(.networkConnectionLost, userInfo: [
            NSURLSessionDownloadTaskResumeData: resumeText.data(using: .utf8) as Any,
        ])
        session?.failDownloadTask(task, error: error)

        // verify promise result
        await assertThrows(response.progress, NetworkError.connectionLost)

        // verify task
        await assertThrows(details.progress.values(), NetworkError.connectionLost)
        try await AsyncAssertEqual(try String(contentsOf: request1.resumePath), resumeText)
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
            for try await _ in response.progress { }
            await batchCompletion.complete()
        }

        var notStartedRequests: [DownloadRequest] = []
        for request in request.requests {
            if await response.details(of: request).task == nil {
                notStartedRequests.append(request)
            }
        }

        XCTAssertEqual(notStartedRequests.count, 1)

        // complete in progress tasks
        var tasks: [CompletedTask] = []
        let startedRequests = request.requests.filter { !notStartedRequests.contains($0) }
        for startedRequest in startedRequests {
            tasks.append(try await completeTask(response, request: startedRequest))
        }

        // Assert first 3 tasks completed but the overall batch not completed.
        for startedRequest in startedRequests {
            for try await _ in await response.details(of: startedRequest).progress.values() { }
        }
        await AsyncAssertEqual(await batchCompletion.completed, false)

        for task in tasks {
            try await verifyCompletedTask(task: task)
        }

        // Assert task started and complete them.
        for notStartedRequest in notStartedRequests {
            await AsyncAssertEqual(await response.details(of: notStartedRequest).task != nil, true)

            let lastTask = try await completeTask(response, request: notStartedRequest)
            try await verifyCompletedTask(task: lastTask)
        }

        // assert the overall  tasks completed
        for try await _ in response.progress { }
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
        for try await _ in diskResponse.progress { }

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
        await assertThrows(response.progress, CancellationError())

        // TODO: Use deterministic solution.
        for _ in 0 ..< 10 {
            await Task.megaYield()
        }

        // verify response is cancelled
        let downloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(downloads.count, 0)

        // other tasks should be cancelled as well
        for request in response.requests {
            let details = await response.details(of: request)
            await assertThrows(details.progress.values(), CancellationError())
        }
    }

    // MARK: Private

    private var downloader: DownloadManager!
    private var session: NetworkSessionFake?

    private let request1 = BatchDownloaderFake.makeDownloadRequest("1")
    private let request2 = BatchDownloaderFake.makeDownloadRequest("2")
    private let request3 = BatchDownloaderFake.makeDownloadRequest("3")
    private let request4 = BatchDownloaderFake.makeDownloadRequest("4")
    private let request5 = BatchDownloaderFake.makeDownloadRequest("5")

    private func completeTask(
        _ batch: DownloadBatchResponse,
        i: Int,
        totalBytes: Int = 100,
        progressLoops: Int = 4,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> CompletedTask {
        try await completeTask(
            batch,
            request: batch.requests[i],
            totalBytes: totalBytes,
            progressLoops: progressLoops,
            file: file,
            line: line
        )
    }

    private func completeTask(
        _ batch: DownloadBatchResponse,
        request: DownloadRequest,
        totalBytes: Int = 100,
        progressLoops: Int = 4,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> CompletedTask {
        let details = await batch.details(of: request)
        let task = try XCTUnwrap(details.task as? SessionTask, file: file, line: line)
        let text = Int.random(in: 0 ..< Int.max).description
        let source = try BatchDownloaderFake.createTextFile(at: "loc-\(request.url.lastPathComponent).txt", content: text)
        XCTAssertTrue(source.isReachable, file: file, line: line)
        let listener = await HistoryProgressListener(details.progress.values())
        await session?.completeDownloadTask(task, location: source, totalBytes: totalBytes, progressLoops: progressLoops)
        return CompletedTask(
            task: task,
            text: text,
            source: source,
            destination: request.destination,
            progressLoops: progressLoops,
            listener: listener,
            progress: details.progress
        )
    }

    private func verifyCompletedTask(task: CompletedTask, file: StaticString = #filePath, line: UInt = #line) async throws {
        var progressValues: [Double] = []
        for i in 0 ..< (task.progressLoops + 1) {
            progressValues.append(1 / Double(task.progressLoops) * Double(i))
        }
        await AsyncAssertEqual(progressValues, await task.listener.values, file: file, line: line)

        // Await completion
        for try await _ in task.progress.values() { }

        // verify downloads saved
        XCTAssertFalse(task.source.isReachable, file: file, line: line)
        XCTAssertEqual(try String(contentsOf: task.destination), task.text, file: file, line: line)
    }

    private func downloadTasks(from batches: [DownloadBatchResponse]) async -> [SessionTask] {
        var tasks = [SessionTask]()
        for batch in batches {
            for request in batch.requests {
                if let task = await batch.details(of: request).task as? SessionTask {
                    tasks.append(task)
                }
            }
        }
        return tasks
    }

    private func assertThrows(
        _ progress: AsyncThrowingPublisher<DownloadProgress>,
        _ expectedError: (some Error)?,
        _ message: @autoclosure () -> String = "Didn't throw",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await AsyncAssertThrows(
            try await { for try await _ in progress { } }(),
            expectedError as NSError?,
            message(),
            file: file,
            line: line
        )
    }
}
