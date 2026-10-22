import BatchDownloaderFake
import Foundation
import Utilities
import XCTest
@testable import BatchDownloader

final class DownloadDestinationReplacementTests: XCTestCase {
    func testCompletedDownloadReplacesExistingFile() async throws {
        let context = BatchDownloaderFake.makeContext()
        let (downloader, session) = await context.makeDownloader()
        let destination = try existingFile(at: "translations/en.db", content: "old", context: context)
        let source = try context.createTextFile(at: UUID().uuidString, content: "new")

        try await context.completeDownload(to: destination, from: source, downloader: downloader, session: session)

        XCTAssertEqual(try String(contentsOf: destination.url, encoding: .utf8), "new")
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
    }

    // An upgrade must keep the installed file when the downloaded file cannot be moved into place.
    func testFailedMoveKeepsExistingFile() async throws {
        let context = BatchDownloaderFake.makeContext()
        let (downloader, session) = await context.makeDownloader()
        let destination = try existingFile(at: "translations/en.db", content: "old", context: context)
        let missingSource = context.downloadsURL.appendingPathComponent("temp/missing", isDirectory: false).url

        do {
            try await context.completeDownload(to: destination, from: missingSource, downloader: downloader, session: session)
            XCTFail("Expected the download to fail")
        } catch {
            XCTAssertTrue(error is FileSystemError, "\(error)")
        }

        XCTAssertEqual(try String(contentsOf: destination.url, encoding: .utf8), "old")
    }

    // MARK: Private

    private func existingFile(at path: String, content: String, context: BatchDownloaderTestContext) throws -> RelativeFilePath {
        let destination = context.downloadsURL.appendingPathComponent(path, isDirectory: false)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent().url, withIntermediateDirectories: true)
        try Data(content.utf8).write(to: destination.url)
        return destination
    }
}
