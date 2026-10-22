//
//  BatchDownloaderFake.swift
//
//
//  Created by Mohamed Afifi on 2023-06-03.
//

import AsyncAlgorithms
import Foundation
import NetworkSupportFake
import SQLitePersistence
import SystemDependencies
import Utilities
import XCTest
@testable import BatchDownloader

/// A downloads sandbox for one test, removed after this object and every database connection it opened are released.
///
/// Test bundles and concurrent runs on the same simulator share the downloads directory, so each context has
/// its own sandbox. Removal never runs if the test process exits first, so the test bundle waits for pending
/// removals when it finishes. The first context in each process also removes sandboxes that earlier processes
/// left behind.
public final class BatchDownloaderTestContext: Sendable {
    // MARK: Lifecycle

    init(downloadsURL: RelativeFilePath) {
        _ = Self.removedLeftoverSandboxes
        _ = Self.registeredBundleObserver
        self.downloadsURL = downloadsURL
    }

    deinit {
        Self.removeWhenClosed(downloadsURL.url, connections: connections)
    }

    // MARK: Public

    public let downloadsURL: RelativeFilePath

    public func makeDownloader(downloads: [SessionTask] = [], fileManager: FileSystem = DefaultFileSystem()) async -> (DownloadManager, NetworkSessionFake) {
        let persistence = makeDownloadsPersistence()
        actor SessionActor {
            var session: NetworkSessionFake!
            let channel = AsyncChannel<Void>()
            func setSession(_ session: NetworkSessionFake) async {
                self.session = session
                await channel.send()
            }
        }
        let sessionActor = SessionActor()
        let downloader = DownloadManager(
            maxSimultaneousDownloads: BatchDownloaderFake.maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                let session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: downloads)
                Task {
                    await sessionActor.setSession(session)
                }
                return session
            },
            persistence: persistence,
            fileManager: fileManager
        )
        await downloader.start()
        await sessionActor.channel.next()
        return (downloader, await sessionActor.session)
    }

    public func makeDownloaderDontWaitForSession(downloads: [SessionTask] = [], fileManager: FileSystem = DefaultFileSystem()) async -> DownloadManager {
        let persistence = makeDownloadsPersistence()
        let downloader = DownloadManager(
            maxSimultaneousDownloads: BatchDownloaderFake.maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                let session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: downloads)
                return session
            },
            persistence: persistence,
            fileManager: fileManager
        )
        return downloader
    }

    public func makeDownloadRequest(_ id: String) -> DownloadRequest {
        DownloadRequest(
            url: URL(validURL: "http://request/\(id)"),
            destination: downloadsURL.appendingPathComponent("/\(id).txt", isDirectory: false)
        )
    }

    /// Downloads `destination` as a single-request batch that `session` finishes from `location`, and waits for the batch to end.
    public func completeDownload(
        to destination: RelativeFilePath,
        from location: URL,
        downloader: DownloadManager,
        session: NetworkSessionFake
    ) async throws {
        let request = DownloadRequest(url: URL(validURL: "https://example.com/\(UUID().uuidString)"), destination: destination)
        let batch = try await downloader.download(DownloadBatchRequest(requests: [request]))
        let details = await batch.details(of: request)
        let task = try XCTUnwrap(details.task as? SessionTask)
        await session.completeDownloadTask(task, location: location, totalBytes: 100, progressLoops: 1)
        for try await _ in batch.progress { }
    }

    public func createTextFile(at path: String, content: String) throws -> URL {
        let directory = downloadsURL.appendingPathComponent("temp", isDirectory: true).url
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(path)
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }

    // MARK: Internal

    /// Removes every sandbox in `directory` whose files were all last modified before `date`.
    ///
    /// A sandbox that a running process still uses keeps changing, so a sandbox untouched since `date`
    /// was left behind by a process that exited before its cleanup ran.
    static func removeSandboxes(in directory: URL, modifiedBefore date: Date) {
        let fileManager = FileManager.default
        let urls = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for url in urls where UUID(uuidString: url.lastPathComponent) != nil && lastModified(url) < date {
            try? fileManager.removeItem(at: url)
        }
    }

    /// Waits up to `timeout` for every pending removal, and returns how many are still pending.
    ///
    /// Turns the current run loop meanwhile, because work queued on the main queue can keep a
    /// downloader, and so its database connection, alive.
    @discardableResult
    static func drainPendingRemovals(timeout: TimeInterval) -> Int {
        let deadline = Date().addingTimeInterval(timeout)
        while pendingRemovals.withCriticalRegion({ $0 > 0 }), Date() < deadline {
            autoreleasepool {
                // A run loop without input sources returns at once, as on a test's background thread.
                if !RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01)) {
                    Thread.sleep(forTimeInterval: 0.01)
                }
            }
        }
        return pendingRemovals.withCriticalRegion { $0 }
    }

    // MARK: Private

    /// Drains pending removals when the test bundle finishes, since the process exits right after.
    private final class BundleObserver: NSObject, XCTestObservation {
        func testBundleDidFinish(_ testBundle: Bundle) {
            let remaining = BatchDownloaderTestContext.drainPendingRemovals(timeout: 10)
            if remaining > 0 {
                // Standard error is unbuffered, so the message survives the exit that follows.
                fputs("\(remaining) downloads test sandboxes were still open when the test bundle finished.\n", stderr)
            }
        }
    }

    private struct WeakConnection {
        weak var connection: DatabaseConnection?
    }

    private static let leftoverSandboxAge: TimeInterval = 60 * 60

    /// Removes leftovers once per process. An hour leaves alone every sandbox a concurrent run still uses.
    private static let removedLeftoverSandboxes: Void = removeSandboxes(
        in: BatchDownloaderFake.downloadsDirectory.url,
        modifiedBefore: Date().addingTimeInterval(-leftoverSandboxAge)
    )

    /// Removals still waiting for their sandbox's database connections to be released.
    private static let pendingRemovals = ManagedCriticalState(0)

    private static let registeredBundleObserver: Void = {
        let register = { XCTestObservationCenter.shared.addTestObserver(BundleObserver()) }
        if Thread.isMainThread {
            register()
        } else {
            DispatchQueue.main.async(execute: register)
        }
    }()

    private let connections = ManagedCriticalState<[WeakConnection]>([])

    /// The latest modification date of `url` and of everything inside it.
    private static func lastModified(_ url: URL) -> Date {
        let key = URLResourceKey.contentModificationDateKey
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [key])
        let urls = [url] + (enumerator?.compactMap { $0 as? URL } ?? [])
        // A file removed meanwhile, or one whose date can't be read, counts as just modified.
        return urls.map { (try? $0.resourceValues(forKeys: [key]).contentModificationDate) ?? .distantFuture }.max() ?? .distantFuture
    }

    /// Removes `url` once every database connection opened on the sandbox is released.
    ///
    /// The last released connection frees the shared database pool, which closes its SQLite connections.
    /// A downloader can outlive its test's assertions, so removal waits in the background instead of
    /// unlinking a live database.
    private static func removeWhenClosed(_ url: URL, connections: ManagedCriticalState<[WeakConnection]>) {
        pendingRemovals.withCriticalRegion { $0 += 1 }
        DispatchQueue.global(qos: .utility).async {
            defer { pendingRemovals.withCriticalRegion { $0 -= 1 } }
            let deadline = Date().addingTimeInterval(30)
            while connections.withCriticalRegion({ $0.contains { $0.connection != nil } }), Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func makeDownloadsPersistence() -> GRDBDownloadsPersistence {
        try? DefaultFileSystem().createDirectory(at: downloadsURL, withIntermediateDirectories: true)
        let downloadsDBPath = downloadsURL.appendingPathComponent("ongoing-downloads.db", isDirectory: false)
        let persistence = GRDBDownloadsPersistence(fileURL: downloadsDBPath.url)
        connections.withCriticalRegion { $0.append(WeakConnection(connection: persistence.db)) }
        return persistence
    }
}

public enum BatchDownloaderFake {
    // MARK: Public

    public static let maxSimultaneousDownloads = 3

    public static func makeContext() -> BatchDownloaderTestContext {
        BatchDownloaderTestContext(
            downloadsURL: downloadsDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        )
    }

    // MARK: Internal

    static let downloadsDirectory = RelativeFilePath("downloads", isDirectory: true)
}
