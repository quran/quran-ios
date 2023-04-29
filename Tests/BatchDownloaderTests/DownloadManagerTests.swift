//
//  DownloadManagerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-22.
//

@testable import BatchDownloader
import TestUtilities
import XCTest

final class DownloadManagerTests: XCTestCase {
    private let fileManager = FileManager.default
    private var downloader: DownloadManager!
    private var session: NetworkSessionFake?
    private var persistence: SqliteDownloadsPersistence!
    private let maxSimultaneousDownloads = 3
    private static let downloads = "downloads"
    private static let downloadsURL = FileManager.documentsURL.appendingPathComponent(downloads)

    private let request1 = DownloadRequest(url: URL(validURL: "http://request/1"), destinationPath: downloads + "/1.txt")
    private let request2 = DownloadRequest(url: URL(validURL: "http://request/2"), destinationPath: downloads + "/2.txt")
    private let request3 = DownloadRequest(url: URL(validURL: "http://request/3"), destinationPath: downloads + "/3.txt")
    private let request4 = DownloadRequest(url: URL(validURL: "http://request/4"), destinationPath: downloads + "/4.txt")
    private let request5 = DownloadRequest(url: URL(validURL: "http://request/5"), destinationPath: downloads + "/5.txt")

    override func setUp() async throws {
        try await super.setUp()
        try fileManager.createDirectory(at: Self.downloadsURL, withIntermediateDirectories: true)
        await newDownloader()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        await Task.megaYield()
        try fileManager.removeItem(at: Self.downloadsURL)
    }

    private func newDownloader(downloads: [SessionTask] = []) async {
        let downloadsDBURL = Self.downloadsURL.appendingPathComponent("ongoing-downloads.db")

        persistence = SqliteDownloadsPersistence(filePath: downloadsDBURL.path)
        downloader = await DownloadManager(
            maxSimultaneousDownloads: maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                self.session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: downloads)
                return self.session!
            },
            persistence: persistence
        )
    }

    func testBackgroundSessionCompletionHandler() async {
        // assign a completion handler
        var calls = 0
        await downloader.setBackgroundSessionCompletion {
            XCTAssertTrue(Thread.isMainThread)
            calls += 1
        }

        // finish background events
        session?.finishBackgroundEvents()
        await Task.megaYield()

        // verify completion handler called
        XCTAssertEqual(calls, 1)
    }

    func testLoadingOnGoingDownload() async throws {
        let emptyDownloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(emptyDownloads.count, 0)

        let batch = DownloadBatchRequest(requests: [request1, request2])
        _ = try await downloader.download(batch)

        // keeping downloads in memory
        let memoryDownloads = await downloader.getOnGoingDownloads()
        let downloads = downloadTasks(from: memoryDownloads)
        XCTAssertEqual(memoryDownloads.count, 1)
        XCTAssertEqual(downloads.count, 2)

        // deallocate downloader & create new one
        downloader = nil
        await newDownloader(downloads: downloads)

        // loaded downlodas from disk
        let diskDownloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(diskDownloads.count, 1)
        XCTAssertEqual(downloadTasks(from: diskDownloads).count, 2)
    }

    func testDownloadBatchCompleted() async throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2])
        let response = try await downloader.download(batch)
        let responses = response.responses
        XCTAssertEqual(responses.count, 2)

        let batchListener = HistoryProgressListener()
        response.progress.progressListeners.insert(batchListener)

        // complete the downloads
        let task1 = try completeTask(response, i: 0)
        let task2 = try completeTask(response, i: 1, totalBytes: 100, progressLoops: 2)

        // wait for async operations to finish
        await Task.megaYield()

        // verify progress and promise result
        verifyCompletedTask(task: task1)
        verifyCompletedTask(task: task2)
        XCTAssertEqual(1.0, batchListener.values.last)
        XCTAssertNotNil(response.promise.value)
    }

    func testDownloadBatch1Success1Error1CancelOthers() async throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2, request3, request4, request5])
        let response = try await downloader.download(batch)

        // complete 1st download
        let task1 = try completeTask(response, i: 0)

        // fail 2nd download with no resume data
        let task2 = try XCTUnwrap(response.responses[1].task as? SessionTask)
        session?.failDownloadTask(task2, error: URLError(.timedOut))

        await Task.megaYield()

        // verify promise result
        XCTAssertEqual(response.promise.error as NSError?, NetworkError.serverNotReachable as NSError)

        // 1st task
        verifyCompletedTask(task: task1)

        // 2nd task
        XCTAssertEqual(response.responses[1].promise.error as NSError?, NetworkError.serverNotReachable as NSError)
        XCTAssertFalse(resumeURL(response: response.responses[1]).isReachable)
        XCTAssertFalse(destinationURL(response: response.responses[1]).isReachable)

        // other tasks should be cancelled
        for i in 2 ..< batch.requests.count {
            XCTAssertEqual(response.responses[i].promise.error as NSError?, URLError(.cancelled) as NSError)
        }
    }

    func testDownloadFailWithResumeData() async throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)

        // fail download with resume data
        let task = try XCTUnwrap(response.responses[0].task as? SessionTask)
        let resumeText = "some data"
        let error = URLError(.networkConnectionLost, userInfo: [
            NSURLSessionDownloadTaskResumeData: resumeText.data(using: .utf8) as Any,
        ])
        session?.failDownloadTask(task, error: error)

        // wait for async operations to finish
        await Task.megaYield()

        // verify promise result
        XCTAssertEqual(response.promise.error as NSError?, NetworkError.connectionLost as NSError)

        // verify task
        XCTAssertEqual(response.responses[0].promise.error as NSError?, NetworkError.connectionLost as NSError)
        XCTAssertEqual(try String(contentsOf: resumeURL(response: response.responses[0])), resumeText)
    }

    func testDownloadBatchAfterEnquingThem() async throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2, request3, request4])
        let response = try await downloader.download(batch)

        XCTAssertNotNil(response.responses[0].task)
        XCTAssertNotNil(response.responses[1].task)
        XCTAssertNotNil(response.responses[2].task)
        XCTAssertNil(response.responses[3].task)

        // complete tasks
        let tasks = try (0 ..< maxSimultaneousDownloads).map {
            try completeTask(response, i: $0)
        }

        // wait for async operations to finish
        await Task.megaYield()

        // assert the batch not completed but the others finished
        XCTAssertNil(response.promise.result)
        XCTAssertNil(response.responses[3].promise.result)
        tasks.forEach {
            verifyCompletedTask(task: $0)
        }

        // assert task started
        XCTAssertNotNil(response.responses[3].task)

        // complete the pending task
        let lastTask = try completeTask(response, i: 3)
        await Task.megaYield()

        // assert the task completed
        XCTAssertNotNil(response.promise.value)
        verifyCompletedTask(task: lastTask)
    }

    func testDownloadBatchAfterEnquingThemInWithDifferentSession() async throws {
        // start first session
        let batch = DownloadBatchRequest(requests: [request1, request2, request3])
        let memoryResponse = try await downloader.download(batch)

        // get the tasks to pass them to the next session
        let memoryDownloads = await downloader.getOnGoingDownloads()
        let downloads = downloadTasks(from: memoryDownloads)

        // complete first task in the first session
        let task1 = try completeTask(memoryResponse, i: 0)

        // wait for all operations to complete, however tasks didn't start yet
        await Task.megaYield()

        // deallocate downloader & create new one
        downloader = nil
        session = nil
        await newDownloader(downloads: downloads)

        let diskDownloads = await downloader.getOnGoingDownloads()
        let diskResponse = try XCTUnwrap(diskDownloads.first)

        // wait for the queue to finish so the session is initialized
        wait(for: downloader.dispatchQueue)

        let task2 = try completeTask(diskResponse, i: 1)
        let task3 = try completeTask(diskResponse, i: 2)

        // wait for async operations to finish
        await Task.megaYield()

        // assert the response & tasks completed
        XCTAssertNotNil(diskResponse.promise.value)
        verifyCompletedTask(task: task1)
        verifyCompletedTask(task: task2)
        verifyCompletedTask(task: task3)
    }

    func testDownloadBatchCancelled() async throws {
        // download a batch of 2 requests, then cancel it
        let batch = DownloadBatchRequest(requests: [request1, request2])
        let response = try await downloader.download(batch)
        // cancel
        await response.cancel()

        // verify response is cancelled
        let downloads = await downloader.getOnGoingDownloads()
        XCTAssertEqual(downloads.count, 0)

        // other tasks should be cancelled as well
        for taskResponse in response.responses {
            XCTAssertEqual(taskResponse.promise.error as NSError?, URLError(.cancelled) as NSError)
        }
    }

    private func completeTask(_ response: DownloadBatchResponse,
                              i: Int,
                              totalBytes: Int = 100,
                              progressLoops: Int = 4,
                              file: StaticString = #filePath,
                              line: UInt = #line) throws -> CompletedTask
    {
        let task = try XCTUnwrap(response.responses[i].task as? SessionTask, file: file, line: line)
        let text = Int.random(in: 0 ..< Int.max).description
        let source = try createTextFile(at: "loc-\(i).txt", content: text)
        let destination = destinationURL(response: response.responses[i])
        XCTAssertTrue(source.isReachable, file: file, line: line)
        let listener = HistoryProgressListener()
        response.responses[i].progress.progressListeners.insert(listener)
        session?.completeDownloadTask(task, location: source, totalBytes: totalBytes, progressLoops: progressLoops)
        return CompletedTask(task: task,
                             text: text,
                             source: source,
                             destination: destination,
                             progressLoops: progressLoops,
                             listener: listener,
                             response: response.responses[i])
    }

    private func verifyCompletedTask(task: CompletedTask, file: StaticString = #filePath, line: UInt = #line) {
        var progressValues: [Double] = []
        for i in 0 ..< (task.progressLoops + 1) {
            progressValues.append(1 / Double(task.progressLoops) * Double(i))
        }
        XCTAssertEqual(progressValues, task.listener.values, file: file, line: line)
        XCTAssertNotNil(task.response.promise.value, file: file, line: line)

        // verify downloads saved
        XCTAssertFalse(task.source.isReachable, file: file, line: line)
        XCTAssertEqual(try String(contentsOf: task.destination), task.text, file: file, line: line)
    }

    private func createTextFile(at path: String, content: String) throws -> URL {
        let directory = Self.downloadsURL.appendingPathComponent("temp")
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(path)
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }

    private func downloadTasks(from responses: [DownloadBatchResponse]?) -> [SessionTask] {
        responses?.flatMap { $0.responses.compactMap { $0.task as? SessionTask } } ?? []
    }

    private func resumeURL(response: DownloadResponse) -> URL {
        FileManager.documentsURL.appendingPathComponent(response.download.request.resumePath)
    }

    private func destinationURL(response: DownloadResponse) -> URL {
        FileManager.documentsURL.appendingPathComponent(response.download.request.destinationPath)
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
