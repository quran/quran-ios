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
        UserDefaults.standard.removeObject(forKey: appDefaultsKey)
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func test_buildDiagnosticsZip_archivesLogsAndDatabasesUnderLogsFolder() throws {
        try Data("log line".utf8).write(to: logsDirectory.appendingPathComponent("app.log"))
        // Documents/databases holds files like translations.db. MobileSync's user_data.db lives
        // in Application Support/databases and is not part of the diagnostics archive.
        try Data("database".utf8).write(to: databasesDirectory.appendingPathComponent("translations.db"))
        let sut = DiagnosticsService(logsDirectory: logsDirectory, databasesDirectory: databasesDirectory)

        let diagnostics = try sut.buildDiagnosticsZip()
        defer { diagnostics.cleanUp() }

        let archive = try Archive(url: diagnostics.url, accessMode: .read)
        XCTAssertEqual(try contents(of: "logs/app.log", in: archive), "log line")
        XCTAssertEqual(try contents(of: "logs/extras/translations.db", in: archive), "database")
        XCTAssertNotNil(archive["logs/extras/UserDefaultsData.json"])
    }

    func test_buildDiagnosticsZip_exportsOnlyTheAppsOwnDefaults() throws {
        UserDefaults.standard.set("value", forKey: appDefaultsKey)
        let sut = DiagnosticsService(logsDirectory: logsDirectory, databasesDirectory: databasesDirectory)

        let diagnostics = try sut.buildDiagnosticsZip()
        defer { diagnostics.cleanUp() }

        let archive = try Archive(url: diagnostics.url, accessMode: .read)
        let json = try XCTUnwrap(contents(of: "logs/extras/UserDefaultsData.json", in: archive))
        let defaults = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        XCTAssertEqual(defaults[appDefaultsKey] as? String, "value")
        // A system-written key from the global domain.
        XCTAssertNil(defaults["AppleLanguages"])
    }

    func test_buildDiagnosticsZip_cleanUpRemovesTheZip() throws {
        let sut = DiagnosticsService(logsDirectory: logsDirectory, databasesDirectory: databasesDirectory)
        let diagnostics = try sut.buildDiagnosticsZip()

        diagnostics.cleanUp()

        XCTAssertFalse(FileManager.default.fileExists(atPath: diagnostics.url.path))
    }

    // MARK: Private

    private let appDefaultsKey = "DiagnosticsServiceTests.appDefault"
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
