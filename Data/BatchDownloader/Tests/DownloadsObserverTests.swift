//
//  DownloadsObserverTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-21.
//

import BatchDownloaderFake
import Combine
import NetworkSupportFake
import XCTest
@testable import BatchDownloader

@MainActor
final class DownloadsObserverTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        testContext = BatchDownloaderFake.makeContext()
        (downloader, session) = await testContext.makeDownloader()
    }

    override func tearDown() async throws {
        downloader = nil
        session = nil
        testContext = nil
        try await super.tearDown()
    }

    func test_endedDownload_removesTheKeyItReportedProgressUnder() async throws {
        let lookup = KeyLookup(key: "key")
        let observer = DownloadsObserver<String>(extractKey: { _ in lookup.key }, showError: { _ in })
        let download = try await startDownload()

        await observer.observe([download])
        await waitForProgress(of: observer) { $0.keys.sorted() == ["key"] }
        lookup.key = nil
        await download.cancel()

        await waitForProgress(of: observer) { $0.isEmpty }
    }

    func test_downloadWithoutKeyWhenObserved_reportsProgressUnderTheKeyFoundLater() async throws {
        let lookup = KeyLookup(key: nil)
        let observer = DownloadsObserver<String>(extractKey: { _ in lookup.key }, showError: { _ in })
        let download = try await startDownload()

        await observer.observe([download])
        lookup.key = "key"
        let task = try XCTUnwrap(session.downloads.first)
        await session.writeDownloadData(task, bytesWritten: 50, totalBytes: 100)

        await waitForProgress(of: observer) { $0.keys.sorted() == ["key"] }
        await download.cancel()
    }

    // MARK: Private

    private final class KeyLookup {
        init(key: String?) {
            self.key = key
        }

        var key: String?
    }

    private var testContext: BatchDownloaderTestContext!
    private var downloader: DownloadManager!
    private var session: NetworkSessionFake!

    private func startDownload() async throws -> DownloadBatchResponse {
        let request = testContext.makeDownloadRequest("1")
        return try await downloader.download(DownloadBatchRequest(requests: [request]))
    }

    private func waitForProgress(
        of observer: DownloadsObserver<String>,
        where condition: @escaping ([String: Double]) -> Bool
    ) async {
        let reached = expectation(description: "Progress matches")
        reached.assertForOverFulfill = false
        let cancellable = observer.progressPublisher.sink { progress in
            if condition(progress) {
                reached.fulfill()
            }
        }
        await fulfillment(of: [reached], timeout: 10)
        cancellable.cancel()
    }
}
