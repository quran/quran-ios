//
//  BatchDownloaderFake.swift
//
//
//  Created by Mohamed Afifi on 2023-06-03.
//

import AsyncAlgorithms
import Foundation
import NetworkSupportFake
import SystemDependencies
import Utilities
import XCTest
@testable import BatchDownloader

public final class BatchDownloaderTestContext: Sendable {
    // MARK: Lifecycle

    init(downloadsURL: RelativeFilePath) {
        self.downloadsURL = downloadsURL
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

    public func tearDown() {
        // Tests may still hold sqlite file descriptors briefly after assertions complete.
        // Keep the per-test sandbox in place to avoid unlinking a live database.
    }

    public func makeDownloadRequest(_ id: String) -> DownloadRequest {
        DownloadRequest(
            url: URL(validURL: "http://request/\(id)"),
            destination: downloadsURL.appendingPathComponent("/\(id).txt", isDirectory: false)
        )
    }

    public func createTextFile(at path: String, content: String) throws -> URL {
        let directory = downloadsURL.appendingPathComponent("temp", isDirectory: true).url
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(path)
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }

    // MARK: Private

    private func makeDownloadsPersistence() -> GRDBDownloadsPersistence {
        try? DefaultFileSystem().createDirectory(at: downloadsURL, withIntermediateDirectories: true)
        let downloadsDBPath = downloadsURL.appendingPathComponent("ongoing-downloads.db", isDirectory: false)
        let persistence = GRDBDownloadsPersistence(fileURL: downloadsDBPath.url)
        return persistence
    }
}

public enum BatchDownloaderFake {
    // MARK: Public

    public static let maxSimultaneousDownloads = 3

    public static func makeContext() -> BatchDownloaderTestContext {
        BatchDownloaderTestContext(
            downloadsURL: RelativeFilePath("\(downloads)/\(UUID().uuidString)", isDirectory: true)
        )
    }

    // MARK: Private

    private static let downloads = "downloads"
}
