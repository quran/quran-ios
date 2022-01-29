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
    private let tempDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("BatchDownloader", isDirectory: true)!
    private static let downloads = "downloads"
    private static let downloadsURL = FileManager.documentsURL.appendingPathComponent(downloads)

    private let request1 = DownloadRequest(url: URL(validURL: "1"), destinationPath: downloads + "/1.txt")
    private let request2 = DownloadRequest(url: URL(validURL: "2"), destinationPath: downloads + "/2.txt")
    private let request3 = DownloadRequest(url: URL(validURL: "3"), destinationPath: downloads + "/3.txt")
    private let request4 = DownloadRequest(url: URL(validURL: "4"), destinationPath: downloads + "/4.txt")
    private let request5 = DownloadRequest(url: URL(validURL: "5"), destinationPath: downloads + "/5.txt")

    override func setUpWithError() throws {
        try super.setUpWithError()
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: Self.downloadsURL, withIntermediateDirectories: true)
        newDownloader()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        waitForQueue()
        try fileManager.removeItem(at: tempDirectory)
        try fileManager.removeItem(at: Self.downloadsURL)
    }


    private func newDownloader(downloads: [DownloadTask] = []) {
        let downloadsURL = tempDirectory.appendingPathComponent("ongoing-downloads.db")

        persistence = SqliteDownloadsPersistence(filePath: downloadsURL.path)
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
        if let queue = session?.queue {
            wait(for: queue)
        }
    }

    func testLoadingOnGoingDownload() throws {
        let emptyDownloads = wait(for: downloader.getOnGoingDownloads())
        XCTAssertEqual(emptyDownloads?.count, 0)

        let batch = DownloadBatchRequest(requests: [request1, request2])
        _ = wait(for: downloader.download(batch))
        waitForQueue()

        // keeping downloads in memory
        let memoryDownloads = wait(for: downloader.getOnGoingDownloads())
        let downloads = downloadTasks(from: memoryDownloads)
        XCTAssertEqual(memoryDownloads?.count, 1)
        XCTAssertEqual(downloads.count, 2)

        // deallocate downloader & create new one
        downloader = nil
        newDownloader(downloads: downloads)

        // loaded downlodas from disk
        let diskDownloads = wait(for: downloader.getOnGoingDownloads())
        XCTAssertEqual(diskDownloads?.count, 1)
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

    func testDownloadBatch1Success1Error() throws {
        // download a batch of 2 requests
        let batch = DownloadBatchRequest(requests: [request1, request2])
        let response = try XCTUnwrap(wait(for: downloader.download(batch)))

        // complete first download
        let task1 = try completeTask(response, i: 0)
        // fail 2nd download
        let task2 = try XCTUnwrap(response.responses[1].task as? DownloadTask)
        session?.failDownloadTask(task2, error: URLError(.timedOut))

        // wait for async operations to finish
        waitForQueue()

        // verify promise result
        verifyCompletedTask(task: task1)
        XCTAssertEqual(response.promise.error as NSError?, NetworkError.serverNotReachable as NSError)
        XCTAssertEqual(response.responses[1].promise.error as NSError?, NetworkError.serverNotReachable as NSError)
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
        let tasks = try (0..<maxSimultaneousDownloads).map {
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

    private func completeTask(_ response: DownloadBatchResponse,
                              i: Int,
                              totalBytes: Int = 100,
                              progressLoops: Int = 4,
                              file: StaticString = #filePath,
                              line: UInt = #line) throws -> CompletedTask {
        let task = try XCTUnwrap(response.responses[i].task as? DownloadTask, file: file, line: line)
        let text = Int.random(in: 0..<Int.max).description
        let source = try createTextFile(at: "loc-\(i).txt", content: text)
        let destination = FileManager.documentsURL.appendingPathComponent(response.responses[i].download.request.destinationPath)
        XCTAssertTrue(source.isReachable)
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

    private func verifyCompletedTask(task: CompletedTask,
                                     file: StaticString = #filePath,
                                     line: UInt = #line) {
        var progressValues: [Double] = []
        for i in 0..<(task.progressLoops + 1) {
            progressValues.append(1 / Double(task.progressLoops) * Double(i))
        }
        XCTAssertEqual(progressValues, Array(task.listener.values.dropFirst()))
        XCTAssertNotNil(task.response.promise.value)

        // verify downloads saved
        XCTAssertFalse(task.source.isReachable)
        XCTAssertEqual(try String(contentsOf: task.destination), task.text)
    }

    private func createTextFile(at path: String, content: String) throws -> URL {
        let url = tempDirectory.appendingPathComponent(path)
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }

    private func downloadTasks(from responses: [DownloadBatchResponse]?) -> [DownloadTask] {
        responses?.flatMap { $0.responses.compactMap { $0.task as? DownloadTask } } ?? []
    }

    private struct CompletedTask {
        let task: DownloadTask
        let text: String
        let source: URL
        let destination: URL
        let progressLoops: Int
        let listener: HistoryProgressListener
        let response: DownloadResponse
    }
}
