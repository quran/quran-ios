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

    override func setUpWithError() throws {
        try super.setUpWithError()
        try fileManager.createDirectory(at: Self.downloadsURL, withIntermediateDirectories: true)
        newDownloader()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        waitForQueue()
        try fileManager.removeItem(at: Self.downloadsURL)
    }

    private func newDownloader(downloads: [Task] = []) {
        let downloadsDBURL = Self.downloadsURL.appendingPathComponent("ongoing-downloads.db")

        persistence = SqliteDownloadsPersistence(filePath: downloadsDBURL.path)
        downloader = DownloadManager(
            maxSimultaneousDownloads: maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                self.session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: downloads)
                return self.session!
            },
            persistence: persistence
        )
    }

    private func waitForQueue() {
        // operation queue used by network session
        wait(for: downloader.operationQueue)
    }

    // Disabling this as it's a flaky test case
    func DISABLED_testBackgroundSessionCompletionHandler() {
        // assign a completion handler
        var calls = 0
        downloader.backgroundSessionCompletionHandler = {
            XCTAssertTrue(Thread.isMainThread)
            calls += 1
        }

        // wait for the queue to finish so the session is initialized
        wait(for: downloader.dispatchQueue)

        // finish background events
        session?.finishBackgroundEvents()

        // wait for the queue to finish
        waitForQueue()

        // wait for the main thread dispatch async as completion is called on main thread
        wait(for: DispatchQueue.main)

        // verify completion handler called
        XCTAssertEqual(calls, 1)
    }

    func testLoadingOnGoingDownload() throws {
        let emptyDownloads = try wait(for: downloader.getOnGoingDownloads())
        XCTAssertEqual(emptyDownloads.count, 0)

        let batch = DownloadBatchRequest(requests: [request1, request2])
        _ = try wait(for: downloader.download(batch))
        waitForQueue()

        // keeping downloads in memory
        let memoryDownloads = try wait(for: downloader.getOnGoingDownloads())
        let downloads = downloadTasks(from: memoryDownloads)
        XCTAssertEqual(memoryDownloads.count, 1)
        XCTAssertEqual(downloads.count, 2)

        // deallocate downloader & create new one
        downloader = nil
        newDownloader(downloads: downloads)

        // loaded downlodas from disk
        let diskDownloads = try wait(for: downloader.getOnGoingDownloads())
        XCTAssertEqual(diskDownloads.count, 1)
        XCTAssertEqual(downloadTasks(from: diskDownloads).count, 2)
    }

    func testDownloadBatchCompleted() throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2])
        let response = try XCTUnwrap(wait(for: downloader.download(batch)))
        let responses = response.responses
        XCTAssertEqual(responses.count, 2)

        let batchListener = HistoryProgressListener()
        response.progress.progressListeners.insert(batchListener)

        // complete the downloads
        let task1 = try completeTask(response, i: 0)
        let task2 = try completeTask(response, i: 1, totalBytes: 100, progressLoops: 2)

        // wait for async operations to finish
        waitForQueue()

        // verify progress and promise result
        verifyCompletedTask(task: task1)
        verifyCompletedTask(task: task2)
        XCTAssertEqual(1.0, batchListener.values.last)
        XCTAssertNotNil(response.promise.value)
    }

    func testDownloadBatch1Success1Error1CancelOthers() throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2, request3, request4, request5])
        let response = try XCTUnwrap(wait(for: downloader.download(batch)))

        // complete 1st download
        let task1 = try completeTask(response, i: 0)

        // fail 2nd download with no resume data
        let task2 = try XCTUnwrap(response.responses[1].task as? Task)
        session?.failDownloadTask(task2, error: URLError(.timedOut))

        waitForQueue()

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

    func testDownloadFailWithResumeData() throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try XCTUnwrap(wait(for: downloader.download(batch)))

        // fail download with resume data
        let task = try XCTUnwrap(response.responses[0].task as? Task)
        let resumeText = "some data"
        let error = URLError(.networkConnectionLost, userInfo: [
            NSURLSessionDownloadTaskResumeData: resumeText.data(using: .utf8) as Any,
        ])
        session?.failDownloadTask(task, error: error)

        // wait for async operations to finish
        waitForQueue()

        // verify promise result
        XCTAssertEqual(response.promise.error as NSError?, NetworkError.connectionLost as NSError)

        // verify task
        XCTAssertEqual(response.responses[0].promise.error as NSError?, NetworkError.connectionLost as NSError)
        XCTAssertEqual(try String(contentsOf: resumeURL(response: response.responses[0])), resumeText)
    }

    func testDownloadBatchAfterEnquingThem() throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2, request3, request4])
        let response = try XCTUnwrap(wait(for: downloader.download(batch)))

        XCTAssertNotNil(response.responses[0].task)
        XCTAssertNotNil(response.responses[1].task)
        XCTAssertNotNil(response.responses[2].task)
        XCTAssertNil(response.responses[3].task)

        // complete tasks
        let tasks = try (0 ..< maxSimultaneousDownloads).map {
            try completeTask(response, i: $0)
        }

        // wait for async operations to finish
        waitForQueue()

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
        waitForQueue()

        // assert the task completed
        XCTAssertNotNil(response.promise.value)
        verifyCompletedTask(task: lastTask)
    }

    func testDownloadBatchAfterEnquingThemInWithDifferentSession() throws {
        // start first session
        let batch = DownloadBatchRequest(requests: [request1, request2, request3])
        let memoryResponse = try wait(for: downloader.download(batch))

        // get the tasks to pass them to the next session
        let memoryDownloads = try wait(for: downloader.getOnGoingDownloads())
        let downloads = downloadTasks(from: memoryDownloads)

        // complete first task in the first session
        let task1 = try completeTask(memoryResponse, i: 0)

        // wait for all operations to complete, however tasks didn't start yet
        waitForQueue()

        // deallocate downloader & create new one
        downloader = nil
        session = nil
        newDownloader(downloads: downloads)

        let diskDownloads = try wait(for: downloader.getOnGoingDownloads())
        let diskResponse = try XCTUnwrap(diskDownloads.first)

        // wait for the queue to finish so the session is initialized
        wait(for: downloader.dispatchQueue)

        let task2 = try completeTask(diskResponse, i: 1)
        let task3 = try completeTask(diskResponse, i: 2)

        // wait for async operations to finish
        waitForQueue()

        // assert the response & tasks completed
        XCTAssertNotNil(diskResponse.promise.value)
        verifyCompletedTask(task: task1)
        verifyCompletedTask(task: task2)
        verifyCompletedTask(task: task3)
    }

    func testDownloadBatchCancelled() throws {
        // download a batch of 2 requests, then cancel it
        let batch = DownloadBatchRequest(requests: [request1, request2])
        let response = try XCTUnwrap(wait(for: downloader.download(batch)))
        // cancel
        response.cancel()

        // wait for async operations to finish
        waitForQueue()

        // verify response is cancelled
        let downloads = try wait(for: downloader.getOnGoingDownloads())
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
        let task = try XCTUnwrap(response.responses[i].task as? Task, file: file, line: line)
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
        XCTAssertEqual(progressValues, Array(task.listener.values.dropFirst()), file: file, line: line)
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

    private func downloadTasks(from responses: [DownloadBatchResponse]?) -> [Task] {
        responses?.flatMap { $0.responses.compactMap { $0.task as? Task } } ?? []
    }

    private func resumeURL(response: DownloadResponse) -> URL {
        FileManager.documentsURL.appendingPathComponent(response.download.request.resumePath)
    }

    private func destinationURL(response: DownloadResponse) -> URL {
        FileManager.documentsURL.appendingPathComponent(response.download.request.destinationPath)
    }

    private struct CompletedTask {
        let task: Task
        let text: String
        let source: URL
        let destination: URL
        let progressLoops: Int
        let listener: HistoryProgressListener
        let response: DownloadResponse
    }
}
