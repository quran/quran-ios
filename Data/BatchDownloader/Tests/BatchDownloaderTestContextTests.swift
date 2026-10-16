//
//  BatchDownloaderTestContextTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-15.
//

import AsyncAlgorithms
import Foundation
import NetworkSupportFake
import XCTest
@testable import BatchDownloader
@testable import BatchDownloaderFake

final class BatchDownloaderTestContextTests: XCTestCase {
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func test_release_removesTheSandboxOnceItsDownloaderIsReleased() async throws {
        var context: BatchDownloaderTestContext? = BatchDownloaderFake.makeContext()
        let sandbox = try XCTUnwrap(context?.downloadsURL.url)
        var downloader: DownloadManager?
        var session: NetworkSessionFake?
        (downloader, session) = try await XCTUnwrap(context).makeDownloader()
        let database = sandbox.appendingPathComponent("ongoing-downloads.db")

        context = nil
        BatchDownloaderTestContext.drainPendingRemovals(timeout: 0.5)
        XCTAssertTrue(FileManager.default.fileExists(atPath: database.path))

        downloader = nil
        session = nil
        BatchDownloaderTestContext.drainPendingRemovals(timeout: 10)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sandbox.path))
    }

    func test_release_removesTheSandboxWhenNoTestReadsTheDownloadsObserver() async throws {
        var context: BatchDownloaderTestContext? = BatchDownloaderFake.makeContext()
        let sandbox = try XCTUnwrap(context?.downloadsURL.url)
        var downloader: DownloadManager?
        var session: NetworkSessionFake?
        (downloader, session) = try await XCTUnwrap(context).makeDownloader()
        session?.downloadsObserver = AsyncChannel()
        let request = try XCTUnwrap(context).makeDownloadRequest("1")
        _ = try await downloader?.download(DownloadBatchRequest(requests: [request]))

        context = nil
        downloader = nil
        session = nil
        BatchDownloaderTestContext.drainPendingRemovals(timeout: 10)

        XCTAssertFalse(FileManager.default.fileExists(atPath: sandbox.path))
    }

    func test_removeSandboxes_removesSandboxesLeftUntouched() throws {
        let leftover = UUID().uuidString
        try createFiles(["\(leftover)/ongoing-downloads.db", "\(leftover)/temp/1.txt"], modifiedOn: twoHoursAgo)

        BatchDownloaderTestContext.removeSandboxes(in: directory, modifiedBefore: oneHourAgo)

        XCTAssertEqual(try contents(), [])
    }

    func test_removeSandboxes_keepsSandboxesWithARecentFile() throws {
        let inUse = UUID().uuidString
        try createFiles(["\(inUse)/ongoing-downloads.db", "\(inUse)/temp/1.txt"], modifiedOn: twoHoursAgo)
        try setModificationDate(Date(), of: "\(inUse)/temp/1.txt")

        BatchDownloaderTestContext.removeSandboxes(in: directory, modifiedBefore: oneHourAgo)

        XCTAssertEqual(try contents(), [inUse])
    }

    func test_removeSandboxes_keepsOtherFiles() throws {
        try createFiles(["audio_files/1.mp3", "ongoing-downloads.db"], modifiedOn: twoHoursAgo)

        BatchDownloaderTestContext.removeSandboxes(in: directory, modifiedBefore: oneHourAgo)

        XCTAssertEqual(try contents(), ["audio_files", "ongoing-downloads.db"])
    }

    // MARK: Private

    private var directory: URL!
    private let oneHourAgo = Date().addingTimeInterval(-60 * 60)
    private let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)

    private func createFiles(_ paths: [String], modifiedOn date: Date) throws {
        for path in paths {
            let url = directory.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data().write(to: url)
        }
        // Sets files first, then their directories deepest first, since adding an entry changes its directory's date.
        let directories = Set(paths.flatMap { path in
            let components = path.split(separator: "/").dropLast()
            return components.indices.map { components[...$0].joined(separator: "/") }
        })
        for path in paths + directories.sorted(by: >) {
            try setModificationDate(date, of: path)
        }
    }

    private func setModificationDate(_ date: Date, of path: String) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: directory.appendingPathComponent(path).path)
    }

    private func contents() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
    }
}
