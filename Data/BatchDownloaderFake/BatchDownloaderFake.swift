//
//  BatchDownloaderFake.swift
//
//
//  Created by Mohamed Afifi on 2023-06-03.
//

import Foundation
import NetworkSupportFake
import XCTest
@testable import BatchDownloader

public enum BatchDownloaderFake {
    // MARK: Public

    public static let maxSimultaneousDownloads = 3
    public static let downloadsURL = FileManager.documentsURL.appendingPathComponent(downloads)

    public static func makeDownloader(downloads: [SessionTask] = []) async -> (DownloadManager, NetworkSessionFake) {
        try? FileManager.default.createDirectory(at: Self.downloadsURL, withIntermediateDirectories: true)
        let downloadsDBURL = Self.downloadsURL.appendingPathComponent("ongoing-downloads.db")

        let persistence = GRDBDownloadsPersistence(fileURL: downloadsDBURL)
        var session: NetworkSessionFake!
        let downloader = DownloadManager(
            maxSimultaneousDownloads: maxSimultaneousDownloads,
            sessionFactory: { delegate, queue in
                session = NetworkSessionFake(queue: queue, delegate: delegate, downloads: downloads)
                return session
            },
            persistence: persistence
        )
        await downloader.start()
        return (downloader, session)
    }

    public static func tearDown() {
        try? FileManager.default.removeItem(at: Self.downloadsURL)
    }

    public static func makeDownloadRequest(_ id: String) -> DownloadRequest {
        DownloadRequest(
            url: URL(validURL: "http://request/\(id)"),
            destinationURL: downloadsURL.appendingPathComponent("/\(id).txt", isDirectory: false)
        )
    }

    public static func createTextFile(at path: String, content: String) throws -> URL {
        let directory = Self.downloadsURL.appendingPathComponent("temp")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(path)
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }

    // MARK: Private

    private static let downloads = "downloads"
}
