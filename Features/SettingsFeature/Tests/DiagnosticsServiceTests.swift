//
//  DiagnosticsServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import XCTest
import ZIPFoundation
@testable import SettingsFeature

final class DiagnosticsServiceTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: databasesDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func test_buildDiagnosticsZip_archivesLogsAndDatabasesUnderLogsFolder() throws {
        try Data("log line".utf8).write(to: logsDirectory.appendingPathComponent("app.log"))
        try Data("database".utf8).write(to: databasesDirectory.appendingPathComponent("quran.db"))
        let sut = DiagnosticsService(logsDirectory: logsDirectory, databasesDirectory: databasesDirectory)

        let diagnostics = try sut.buildDiagnosticsZip()
        defer { diagnostics.cleanUp() }

        let archive = try Archive(url: diagnostics.url, accessMode: .read)
        XCTAssertEqual(try contents(of: "logs/app.log", in: archive), "log line")
        XCTAssertEqual(try contents(of: "logs/extras/quran.db", in: archive), "database")
        XCTAssertNotNil(archive["logs/extras/UserDefaultsData.json"])
    }

    func test_buildDiagnosticsZip_cleanUpRemovesTheZip() throws {
        let sut = DiagnosticsService(logsDirectory: logsDirectory, databasesDirectory: databasesDirectory)
        let diagnostics = try sut.buildDiagnosticsZip()

        diagnostics.cleanUp()

        XCTAssertFalse(FileManager.default.fileExists(atPath: diagnostics.url.path))
    }

    // MARK: Private

    private var directory: URL!

    private var logsDirectory: URL {
        directory.appendingPathComponent("logs", isDirectory: true)
    }

    private var databasesDirectory: URL {
        directory.appendingPathComponent("databases", isDirectory: true)
    }

    private func contents(of path: String, in archive: Archive) throws -> String? {
        let entry = try XCTUnwrap(archive[path], path)
        var data = Data()
        _ = try archive.extract(entry) { data.append($0) }
        return String(data: data, encoding: .utf8)
    }
}
