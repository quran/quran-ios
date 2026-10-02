//
//  SettingsRootViewModelAppearanceTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Analytics
import AppIconFeature
import AudioDownloadsFeature
import Localization
import ReadingSelectorFeature
import SettingsService
import SystemDependenciesFake
import TranslationsFeature
import UIKit
import XCTest
@testable import NoorUI
@testable import SettingsFeature

/// Covers the Appearance section (the appearance mode picker and the App Icon row)
/// and the Audio Playback row.
@MainActor
final class SettingsRootViewModelAppearanceTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        iconAccess = AlternateIconAccessFake()
        bundle = SystemBundleFake()
        bundle.info["CFBundleIcons"] = [
            "CFBundleAlternateIcons": ["AppIcon-Blue": ["CFBundleIconName": "AppIcon-Blue"]],
        ]
        originalAppearanceMode = ThemeService.shared.appearanceMode
    }

    override func tearDown() async throws {
        ThemeService.shared.appearanceMode = originalAppearanceMode
        AppIconAccent.setCurrent(nil)
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

    // MARK: App Icon

    func test_appIconRow_showsCurrentIconName() {
        iconAccess.alternateIconName = "AppIcon-Blue"

        let sut = makeSUT()

        XCTAssertTrue(sut.isAppIconAvailable)
        XCTAssertEqual(sut.appIconOption.name, "Blue")
    }

    func test_appIconRow_hiddenWithoutPlatformSupport() {
        iconAccess.supportsAlternateIcons = false

        let sut = makeSUT()

        XCTAssertFalse(sut.isAppIconAvailable)
    }

    func test_appIconRow_hiddenWhenAppDeclaresNoAlternateIcons() {
        bundle.info["CFBundleIcons"] = nil

        let sut = makeSUT()

        XCTAssertFalse(sut.isAppIconAvailable)
    }

    func test_appIconRow_followsIconChange() async throws {
        let service = makeService()
        let sut = makeSUT(appIconService: service)
        XCTAssertEqual(sut.appIconOption.name, "Navy")

        try await service.set(blue)

        XCTAssertEqual(sut.appIconOption.name, "Blue")
    }

    // MARK: Audio Playback

    func test_audioPlaybackRow_pushesAudioPlayback() {
        let navigationController = UINavigationController()
        let sut = makeSUT(navigationController: navigationController)

        sut.navigateToAudioPlayback()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertEqual(navigationController.topViewController?.title, l("audio.playback.title"))
    }

    // MARK: Private

    private let navy = AppIconOption(
        id: "navy",
        alternateIconName: nil,
        name: "Navy",
        previewImageName: "app-icon-navy",
        accent: AppIconAccent(light: .black, dark: .white, onDark: .black)
    )
    private let blue = AppIconOption(
        id: "blue",
        alternateIconName: "AppIcon-Blue",
        name: "Blue",
        previewImageName: "app-icon-blue",
        accent: AppIconAccent(light: .systemBlue, dark: .systemBlue, onDark: .black)
    )

    private var iconAccess: AlternateIconAccessFake!
    private var bundle: SystemBundleFake!
    private var originalAppearanceMode = AppearanceMode.auto

    private var catalog: AppIconCatalog {
        AppIconCatalog(sections: [.init(id: "all", title: "All", previewSize: .large, options: [navy, blue])])
    }

    private func makeService() -> AppIconService {
        AppIconService(catalog: catalog, iconAccess: iconAccess, bundle: bundle)
    }

    private func makeSUT(
        analytics: AnalyticsLibrary = NoopAnalytics(),
        appIconService: AppIconService? = nil,
        navigationController: UINavigationController? = nil
    ) -> SettingsRootViewModel {
        let navigationController = navigationController ?? UINavigationController()
        let container = AppDependenciesStub(appIconCatalog: catalog)
        let appIconService = appIconService ?? makeService()
        #if QURAN_SYNC
        return SettingsRootViewModel(
            analytics: analytics,
            reviewService: ReviewService(analytics: NoopAnalytics()),
            authenticationClient: container.authenticationClient,
            legacyDataImportCoordinator: container.legacyDataImportCoordinator,
            audioPlaybackBuilder: AudioPlaybackBuilder(),
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            appIconService: appIconService,
            appIconBuilder: AppIconBuilder(container: container),
            quranProfileURL: container.quranProfileURL,
            navigationController: navigationController
        )
        #else
        return SettingsRootViewModel(
            analytics: analytics,
            reviewService: ReviewService(analytics: NoopAnalytics()),
            audioPlaybackBuilder: AudioPlaybackBuilder(),
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            appIconService: appIconService,
            appIconBuilder: AppIconBuilder(container: container),
            navigationController: navigationController
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
