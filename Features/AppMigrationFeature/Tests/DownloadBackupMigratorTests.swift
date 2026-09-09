import AppMigrator
import Foundation
import XCTest
@testable import AppMigrationFeature

final class DownloadBackupMigratorTests: XCTestCase {
    override func setUpWithError() throws {
        documentsURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: documentsURL)
    }

    func testExcludesExistingDownloadsAndPreservesTheirContents() async throws {
        for name in directoryNames {
            let directory = documentsURL.appendingPathComponent(name, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("download".utf8).write(to: directory.appendingPathComponent("existing.bin"))
        }

        await migrate()

        for name in directoryNames {
            let directory = documentsURL.appendingPathComponent(name, isDirectory: true)
            XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
            XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("existing.bin")), Data("download".utf8))
        }
        XCTAssertNotEqual(try documentsURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    func testCreatesExcludedRootsBeforeOlderMigrationsPopulateThem() async throws {
        await migrate()

        for name in directoryNames {
            let directory = documentsURL.appendingPathComponent(name, isDirectory: true)
            XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        }
    }

    func testContinuesAfterOneDirectoryFails() async throws {
        try Data().write(to: documentsURL.appendingPathComponent("audio_files"))

        await migrate()

        for name in ["translations", "readings"] {
            let directory = documentsURL.appendingPathComponent(name, isDirectory: true)
            XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        }
    }

    func testRepeatedMigrationKeepsDirectoriesExcluded() async throws {
        await migrate()
        await migrate()

        for name in directoryNames {
            let directory = documentsURL.appendingPathComponent(name, isDirectory: true)
            XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        }
    }

    private var documentsURL: URL!
    private let directoryNames = ["audio_files", "translations", "readings"]

    private func migrate() async {
        await DownloadBackupMigrator(documentsURL: documentsURL).execute(update: .update(from: "2.6.8", to: "2.6.9"))
    }
}
