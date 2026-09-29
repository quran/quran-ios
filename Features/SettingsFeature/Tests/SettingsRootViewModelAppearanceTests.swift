//
//  SettingsRootViewModelAppearanceTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Analytics
import AudioDownloadsFeature
import NoorUI
import ReadingSelectorFeature
import SettingsService
import TranslationsFeature
import UIKit
import XCTest
@testable import SettingsFeature

/// Covers the Appearance section: the appearance mode picker.
@MainActor
final class SettingsRootViewModelAppearanceTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        originalAppearanceMode = ThemeService.shared.appearanceMode
    }

    override func tearDown() async throws {
        ThemeService.shared.appearanceMode = originalAppearanceMode
        try await super.tearDown()
    }

    // MARK: Appearance mode

    func test_selectAppearanceMode_appliesAndLogsChange() {
        let analytics = AnalyticsRecorder()
        let sut = makeSUT(analytics: analytics)
        let mode: AppearanceMode = sut.appearanceMode == .dark ? .light : .dark

        sut.selectAppearanceMode(mode)

        XCTAssertEqual(sut.appearanceMode, mode)
        XCTAssertEqual(ThemeService.shared.appearanceMode, mode)
        XCTAssertEqual(analytics.events, [AnalyticsEvent(name: "ChangeAppearanceMode", value: mode.description)])
    }

    func test_selectAppearanceMode_ignoresCurrentMode() {
        let analytics = AnalyticsRecorder()
        let sut = makeSUT(analytics: analytics)

        sut.selectAppearanceMode(sut.appearanceMode)

        XCTAssertEqual(analytics.events, [])
    }

    // MARK: Private

    private var originalAppearanceMode = AppearanceMode.auto

    private func makeSUT(analytics: AnalyticsLibrary = NoopAnalytics()) -> SettingsRootViewModel {
        let container = AppDependenciesStub()
        #if QURAN_SYNC
        return SettingsRootViewModel(
            analytics: analytics,
            reviewService: ReviewService(analytics: NoopAnalytics()),
            authenticationClient: container.authenticationClient,
            legacyDataImportCoordinator: container.legacyDataImportCoordinator,
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            quranProfileURL: container.quranProfileURL,
            navigationController: UINavigationController()
        )
        #else
        return SettingsRootViewModel(
            analytics: analytics,
            reviewService: ReviewService(analytics: NoopAnalytics()),
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            navigationController: UINavigationController()
        )
        #endif
    }
}

private struct AnalyticsEvent: Equatable {
    let name: String
    let value: String
}

private final class AnalyticsRecorder: AnalyticsLibrary, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []

    func logEvent(_ name: String, value: String) {
        events.append(.init(name: name, value: value))
    }
}
