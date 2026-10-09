//
//  DownloadManagerCancellationTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import BatchDownloaderFake
import NetworkSupportFake
import XCTest
@testable import BatchDownloader

final class DownloadManagerCancellationTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        testContext = BatchDownloaderFake.makeContext()
        request1 = testContext.makeDownloadRequest("1")
        request2 = testContext.makeDownloadRequest("2")
    }

    override func tearDown() async throws {
        try await super.tearDown()
        downloader = nil
        request1 = nil
        request2 = nil
        testContext.tearDown()
        testContext = nil
    }

    func testCancelledCallerReturnsAfterRemovingBatch() async throws {
        downloader = await testContext.makeDownloader().0
        _ = try await downloader.download(DownloadBatchRequest(requests: [request1, request2]))

        let cancel = startCancel()
        cancel.cancel()

        await assertReturnAndRemoveBatches([cancel])
    }

    func testRestoredCompletedBatchIsRemovedOnStart() async throws {
        // The app was suspended after the last download finished but before the batch was cleaned up.
        try await persistCompletedBatch()

        downloader = await testContext.makeDownloader().0

        await assertBatchesRemoved()
    }

    func testRepeatedCancelsReturnForRestoredCompletedBatch() async throws {
        try await persistCompletedBatch()
        downloader = await testContext.makeDownloader().0

        // Mirrors AsyncButton: each tap cancels the previous tap's task.
        let firstTap = startCancel()
        let secondTap = startCancel()
        firstTap.cancel()

        await assertReturnAndRemoveBatches([firstTap, secondTap])
    }

    // MARK: Private

    private var downloader: DownloadManager!
    private var testContext: BatchDownloaderTestContext!
    private var request1: DownloadRequest!
    private var request2: DownloadRequest!

    private func persistCompletedBatch() async throws {
        try FileManager.default.createDirectory(at: testContext.downloadsURL.url, withIntermediateDirectories: true)
        let databaseURL = testContext.downloadsURL.appendingPathComponent("ongoing-downloads.db", isDirectory: false)
        let persistence = GRDBDownloadsPersistence(fileURL: databaseURL.url)
        let batch = try await persistence.insert(batch: DownloadBatchRequest(requests: [request1, request2]))
        let completed = batch.downloads.map {
            Download(taskId: $0.taskId, request: $0.request, status: .completed, batchId: batch.id)
        }
        try await persistence.update(downloads: completed)
    }

    private func startCancel() -> Task<Void, Never> {
        let downloader = downloader!
        return Task {
            let downloads = await downloader.getOnGoingDownloads()
            await downloader.cancel(downloads: downloads)
        }
    }

    private func assertReturnAndRemoveBatches(
        _ cancels: [Task<Void, Never>],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let returned = expectation(description: "cancel(downloads:) returned")
        returned.expectedFulfillmentCount = cancels.count
        for cancel in cancels {
            Task {
                await cancel.value
                returned.fulfill()
            }
        }
        // Bounded wait: a stuck cancel must fail the test, not hang the run.
        await fulfillment(of: [returned], timeout: 5)

        await assertBatchesRemoved(file: file, line: line)
    }

    private func assertBatchesRemoved(file: StaticString = #filePath, line: UInt = #line) async {
        let downloader = downloader!
        let removed = expectation(description: "ongoing downloads are empty")
        let poll = Task {
            while await !downloader.getOnGoingDownloads().isEmpty {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            removed.fulfill()
        }
        await fulfillment(of: [removed], timeout: 5)
        poll.cancel()
    }
}
