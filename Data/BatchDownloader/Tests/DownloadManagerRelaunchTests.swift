//
//  DownloadManagerRelaunchTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-22.
//

import BatchDownloaderFake
import NetworkSupport
import NetworkSupportFake
import Utilities
import XCTest
@testable import BatchDownloader

/// iOS relaunches the app for a background session whose downloads finished while the app was terminated,
/// and the session delivers them as soon as it's created.
final class DownloadManagerRelaunchTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        testContext = BatchDownloaderFake.makeContext()
        request = testContext.makeDownloadRequest("1")
    }

    override func tearDown() async throws {
        try await super.tearDown()
        downloader = nil
        session = nil
        request = nil
        testContext = nil
    }

    func testRelaunchKeepsDownloadDeliveredBeforeSessionStopsListingIt() async throws {
        let task = try await persistRunningDownload()
        let location = try testContext.createTextFile(at: "finished.txt", content: "downloaded")

        // URLSession lists a finished task until it delivers the task's completion.
        let events = await relaunch(listing: [task]) { session, delegate in
            await Self.deliverFinishedDownload(task, from: location, session: session, delegate: delegate)
            session.downloads.removeAll { $0 === task }
        }
        await events.value

        await assertBatchesRemoved()
        XCTAssertEqual(try String(contentsOf: request.destination.url, encoding: .utf8), "downloaded")
        XCTAssertTrue(session.downloads.isEmpty, "The finished download was downloaded again")
    }

    func testRelaunchKeepsDownloadDeliveredWhileSessionStillListsIt() async throws {
        let task = try await persistRunningDownload()
        let location = try testContext.createTextFile(at: "finished.txt", content: "downloaded")

        let events = await relaunch(listing: [task]) { session, delegate in
            await Self.deliverFinishedDownload(task, from: location, session: session, delegate: delegate)
        }
        await events.value

        await assertBatchesRemoved()
        XCTAssertEqual(try String(contentsOf: request.destination.url, encoding: .utf8), "downloaded")
        XCTAssertEqual(session.downloads.map(ObjectIdentifier.init), [ObjectIdentifier(task)], "Started another download task")
    }

    // MARK: Private

    /// A timing seam, not a fake: if the session's relaunch events already started when the saved batches
    /// load, lets them finish first, as if they arrived while the batches were still loading.
    private final class LoadingAfterSessionEventsPersistence: DownloadsPersistence {
        // MARK: Lifecycle

        init(_ persistence: GRDBDownloadsPersistence) {
            self.persistence = persistence
        }

        // MARK: Internal

        let sessionEvents = ManagedCriticalState<Task<Void, Never>?>(nil)

        func retrieveAll() async throws -> [DownloadBatch] {
            await sessionEvents.withCriticalRegion { $0 }?.value
            return try await persistence.retrieveAll()
        }

        func insert(batch: DownloadBatchRequest) async throws -> DownloadBatch {
            try await persistence.insert(batch: batch)
        }

        func update(downloads: [Download]) async throws {
            try await persistence.update(downloads: downloads)
        }

        func delete(batchIds: [Int64]) async throws {
            try await persistence.delete(batchIds: batchIds)
        }

        // MARK: Private

        private let persistence: GRDBDownloadsPersistence
    }

    private var downloader: DownloadManager!
    private var session: NetworkSessionFake!
    private var testContext: BatchDownloaderTestContext!
    private var request: DownloadRequest!

    /// Reports that `task` finished downloading to `location`, as URLSession does.
    private static func deliverFinishedDownload(
        _ task: SessionTask,
        from location: URL,
        session: NetworkSessionFake,
        delegate: NetworkSessionDelegate
    ) async {
        task.response = HTTPURLResponse(url: task.originalRequest!.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
        await delegate.networkSession(session, downloadTask: task, didFinishDownloadingTo: location)
        await delegate.networkSession(session, task: task, didCompleteWithError: nil)
    }

    /// Starts downloading `request` and terminates the app, returning the task that downloads it in the background.
    private func persistRunningDownload() async throws -> SessionTask {
        let (firstLaunch, _) = await testContext.makeDownloader()
        let batch = try await firstLaunch.download(DownloadBatchRequest(requests: [request]))
        let details = await batch.details(of: request)
        return try XCTUnwrap(details.task as? SessionTask)
    }

    /// Relaunches the app with a session listing `tasks`, which starts `sessionEvents` once it's created.
    private func relaunch(
        listing tasks: [SessionTask],
        sessionEvents: @escaping @Sendable (NetworkSessionFake, NetworkSessionDelegate) async -> Void
    ) async -> Task<Void, Never> {
        let databaseURL = testContext.downloadsURL.appendingPathComponent("ongoing-downloads.db", isDirectory: false)
        let persistence = LoadingAfterSessionEventsPersistence(GRDBDownloadsPersistence(fileURL: databaseURL.url))
        let createdSession = ManagedCriticalState<NetworkSessionFake?>(nil)
        downloader = DownloadManager(
            maxSimultaneousDownloads: BatchDownloaderFake.maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                let session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: tasks)
                createdSession.withCriticalRegion { $0 = session }
                persistence.sessionEvents.withCriticalRegion { $0 = Task { await sessionEvents(session, delegate) } }
                return session
            },
            persistence: persistence
        )
        await downloader.start()
        session = createdSession.withCriticalRegion { $0 }
        return persistence.sessionEvents.withCriticalRegion { $0 }!
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
        // Bounded wait: a stuck download must fail the test, not hang the run.
        let result = await XCTWaiter.fulfillment(of: [removed], timeout: 5)
        poll.cancel()
        XCTAssertEqual(result, .completed, "The batch is still ongoing", file: file, line: line)
    }
}
