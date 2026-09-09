import BatchDownloaderFake
import Foundation
import NetworkSupportFake
import Utilities
import XCTest
@testable import BatchDownloader

final class DownloadBackupTests: XCTestCase {
    func testCompletedDownloadsExcludeTheirDirectories() async throws {
        let context = BatchDownloaderFake.makeContext()
        defer { context.tearDown() }
        let (downloader, session) = await context.makeDownloader()

        for path in ["audio_files/reciter/audio.mp3", "audio_files/reciter/timing.zip", "translations/en.zip", "readings/hafs/pages.zip"] {
            let destination = context.downloadsURL.appendingPathComponent(path, isDirectory: false)
            try await completeDownload(destination: destination, context: context, downloader: downloader, session: session)

            let directory = destination.deletingLastPathComponent().url
            XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
            XCTAssertEqual(try String(contentsOf: destination), "downloaded content")
        }

        XCTAssertNotEqual(try context.downloadsURL.url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    func testRecreatedDownloadDirectoryIsExcludedAgain() async throws {
        let context = BatchDownloaderFake.makeContext()
        defer { context.tearDown() }
        let (downloader, session) = await context.makeDownloader()
        let destination = context.downloadsURL.appendingPathComponent("audio_files/reciter/audio.mp3", isDirectory: false)
        try await completeDownload(destination: destination, context: context, downloader: downloader, session: session)
        try FileManager.default.removeItem(at: destination.deletingLastPathComponent().url)

        try await completeDownload(destination: destination, context: context, downloader: downloader, session: session)

        let directory = destination.deletingLastPathComponent().url
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    private func completeDownload(
        destination: RelativeFilePath,
        context: BatchDownloaderTestContext,
        downloader: DownloadManager,
        session: NetworkSessionFake
    ) async throws {
        let request = DownloadRequest(url: URL(string: "https://example.com/\(UUID().uuidString)")!, destination: destination)
        let batch = try await downloader.download(DownloadBatchRequest(requests: [request]))
        let details = await batch.details(of: request)
        let task = try XCTUnwrap(details.task as? SessionTask)
        let source = try context.createTextFile(at: UUID().uuidString, content: "downloaded content")
        await session.completeDownloadTask(task, location: source, totalBytes: 100, progressLoops: 1)
        for try await _ in batch.progress { }
    }
}
