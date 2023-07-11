//
//  BatchDownloaderFake.swift
//
//
//  Created by Mohamed Afifi on 2023-06-03.
//

import AsyncAlgorithms
import Foundation
import NetworkSupportFake
import Utilities
import XCTest
@testable import BatchDownloader

public enum BatchDownloaderFake {
    // MARK: Public

    public static let maxSimultaneousDownloads = 3
    public static let downloadsURL = RelativeFilePath(downloads, isDirectory: true)

    public static func makeDownloader(downloads: [SessionTask] = []) async -> (DownloadManager, NetworkSessionFake) {
        try? FileManager.default.createDirectory(at: Self.downloadsURL, withIntermediateDirectories: true)
        let downloadsDBPath = Self.downloadsURL.appendingPathComponent("ongoing-downloads.db", isDirectory: false)

        let persistence = GRDBDownloadsPersistence(fileURL: downloadsDBPath.url)
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
            maxSimultaneousDownloads: maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                let session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: downloads)
                Task {
                    await sessionActor.setSession(session)
                }
                return session
            },
            persistence: persistence
        )
        await downloader.start()
        await sessionActor.channel.next()
        return (downloader, await sessionActor.session)
    }

    public static func tearDown() {
        try? FileManager.default.removeItem(at: Self.downloadsURL)
    }

    public static func makeDownloadRequest(_ id: String) -> DownloadRequest {
        DownloadRequest(
            url: URL(validURL: "http://request/\(id)"),
            destination: downloadsURL.appendingPathComponent("/\(id).txt", isDirectory: false)
        )
    }

    public static func createTextFile(at path: String, content: String) throws -> URL {
        let directory = Self.downloadsURL.appendingPathComponent("temp", isDirectory: true).url
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(path)
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }

    // MARK: Private

    private static let downloads = "downloads"
}
