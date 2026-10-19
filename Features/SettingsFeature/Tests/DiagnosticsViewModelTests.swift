//
//  DiagnosticsViewModelTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-12.
//

import Localization
import SystemDependenciesFake
import XCTest
@testable import SettingsFeature

@MainActor
final class DiagnosticsViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func test_enableDebugLoggingFooter_saysAlwaysOnWhenTheBuildAlwaysLogsDebug() {
        let sut = makeSUT(isDebugLoggingAlwaysEnabled: true)

        XCTAssertEqual(sut.enableDebugLoggingFooter, l("diagnostics.enable_debug_logs.always_on"))
    }

    func test_enableDebugLoggingFooter_asksForARestartOtherwise() {
        let sut = makeSUT(isDebugLoggingAlwaysEnabled: false)

        XCTAssertEqual(sut.enableDebugLoggingFooter, l("diagnostics.enable_debug_logs.details"))
    }

    func test_appVersion_showsTheVersionAndBuildLeftToRight() {
        bundle.info["CFBundleShortVersionString"] = "2.4.0"
        bundle.info["CFBundleVersion"] = "310"
        let sut = makeSUT()

        XCTAssertEqual(sut.appVersion, "\u{2066}2.4.0 (310)\u{2069}")
    }

    func test_appVersion_showsTheVersionAloneWithoutABuild() {
        bundle.info["CFBundleShortVersionString"] = "2.4.0"
        let sut = makeSUT()

        XCTAssertEqual(sut.appVersion, "\u{2066}2.4.0\u{2069}")
    }

    // MARK: Private

    private var directory: URL!
    private let bundle = SystemBundleFake()

    private func makeSUT(isDebugLoggingAlwaysEnabled: Bool = true) -> DiagnosticsViewModel {
        DiagnosticsViewModel(
            diagnosticsService: DiagnosticsService(
                logsDirectory: directory.appendingPathComponent("logs", isDirectory: true),
                databasesDirectory: directory.appendingPathComponent("databases", isDirectory: true)
            ),
            isDebugLoggingAlwaysEnabled: isDebugLoggingAlwaysEnabled,
            bundle: bundle,
            navigationController: nil
        )
    }
}
