//
//  AnalyticsUserPropertiesReporterTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import AnalyticsFake
#if QURAN_SYNC
import AuthenticationClientFake
#endif
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import ReciterService
import ReciterServiceFake
import SystemDependenciesFake
import TranslationService
import UIKit
import WordTextService
import XCTest
@testable import AppStructureFeature
@testable import NoorUI

@MainActor
final class AnalyticsUserPropertiesReporterTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        saved = SavedReporterPreferences()
        analytics = AnalyticsLibrarySpy()
        iconAccess = AlternateIconAccessFake(alternateIconName: "AppIcon-Blue")
        #if QURAN_SYNC
        authenticationClient = AuthenticationClientFake()
        authenticationClient.authenticationStateValue = .authenticated
        notificationCenter = NotificationCenter()
        #endif
        setKnownPreferences()
    }

    override func tearDown() async throws {
        sut = nil
        saved.restore()
        AppIconAccent.setCurrent(nil)
        try await super.tearDown()
    }

    // MARK: Start

    func test_start_reportsCurrentValues() async {
        await start()

        XCTAssertEqual(analytics.userProperties, expectedProperties)
    }

    // MARK: Audio

    func test_playbackRateChange_updatesIt() async {
        await assertChange(of: .playbackRate, from: "1.25", to: "2.0") {
            AudioPreferences.shared.playbackRate = 2
        }
    }

    func test_audioEndChange_updatesIt() async {
        await assertChange(of: .audioEnd, from: "hizb", to: "page") {
            AudioPreferences.shared.audioEnd = .page
        }
    }

    func test_verseRepeatChange_updatesIt() async {
        await assertChange(of: .verseRepeat, from: "3", to: "inf") {
            AudioPreferences.shared.verseRuns = .indefinite
        }
    }

    func test_rangeRepeatChange_updatesIt() async {
        await assertChange(of: .rangeRepeat, from: "inf", to: "2") {
            AudioPreferences.shared.listRuns = .finite(2)
        }
    }

    func test_versePauseChange_updatesIt() async {
        await assertChange(of: .versePause, from: "0.5", to: "0.0") {
            AudioPreferences.shared.verseDelay = .none
        }
    }

    func test_rangePauseChange_updatesIt() async {
        await assertChange(of: .rangePause, from: "2.0", to: "10.0") {
            AudioPreferences.shared.repetitionDelay = .tenSeconds
        }
    }

    func test_streamingChange_updatesIt() async {
        await assertChange(of: .audioStreaming, from: "on", to: "off") {
            AudioPreferences.shared.streamingEnabled = false
        }
    }

    func test_reciterChange_updatesIt() async {
        await assertChange(of: .reciter, from: "afasy_gapless", to: "reciter1") {
            ReciterPreferences.shared.lastSelectedReciterId = Reciter.gappedReciter.id
        }
    }

    func test_unavailableReciter_reportsTheFirstReciterLikePlayback() async throws {
        let retrievedReciters = await makeReciterRetriever().getReciters()
        let firstReciter = try XCTUnwrap(retrievedReciters.first)
        let expected = AnalyticsUserPropertyValue.reciter(nameKey: firstReciter.nameKey)
        ReciterPreferences.shared.lastSelectedReciterId = 999

        await start()

        XCTAssertEqual(analytics.changes(of: .reciter), [expected])
    }

    func test_unchangedValue_isNotReportedAgain() async {
        await start()

        AudioPreferences.shared.playbackRate = 1.25
        await settle()

        XCTAssertEqual(analytics.changes(of: .playbackRate), ["1.25"])
    }

    func test_changeFromAnotherThread_updatesIt() async {
        await start()

        await Task.detached {
            AudioPreferences.shared.audioEnd = .quran
        }.value
        await settle()

        XCTAssertEqual(analytics.changes(of: .audioEnd), ["hizb", "quran"])
    }

    // MARK: Reading

    func test_mushafChange_updatesIt() async {
        await assertChange(of: .mushaf, from: "tajweed", to: "indopak") {
            ReadingPreferences.shared.reading = .indoPak
        }
    }

    func test_quranModeChange_updatesIt() async {
        await assertChange(of: .quranMode, from: "translation", to: "arabic") {
            QuranContentStatePreferences.shared.quranMode = .arabic
        }
    }

    func test_translationsCountChange_updatesItsBucket() async {
        await assertChange(of: .translationsCount, from: "2", to: "3+") {
            SelectedTranslationsPreferences.shared.selectedTranslationIds = [1, 2, 3, 4]
        }
    }

    func test_arabicFontSizeChange_updatesIt() async {
        await assertChange(of: .arabicFontSize, from: "xLarge", to: "accessibility5") {
            FontSizePreferences.shared.arabicFontSize = .accessibility5
        }
    }

    func test_translationFontSizeChange_updatesIt() async {
        await assertChange(of: .translationFontSize, from: "small", to: "xxxLarge") {
            FontSizePreferences.shared.translationFontSize = .xxxLarge
        }
    }

    func test_appearanceChange_updatesIt() async {
        await assertChange(of: .appearance, from: "dark", to: "light") {
            ThemeService.shared.appearanceMode = .light
        }
    }

    func test_themeStyleChange_updatesIt() async {
        await assertChange(of: .themeStyle, from: "quiet", to: "calm") {
            ThemeService.shared.themeStyle = .calm
        }
    }

    func test_turningWordPointerOff_updatesIt() async {
        await assertChange(of: .wordPointer, from: "transliteration", to: "off") {
            WordTextPreferences.shared.isWordPointerActive = false
        }
    }

    func test_wordPointerTextChange_updatesIt() async {
        await assertChange(of: .wordPointer, from: "transliteration", to: "translation") {
            WordTextPreferences.shared.wordTextType = .translation
        }
    }

    func test_twoPagesChange_updatesIt() async {
        await assertChange(of: .twoPages, from: "off", to: "on") {
            QuranContentStatePreferences.shared.twoPagesEnabled = true
        }
    }

    func test_arabicInTranslationChange_updatesIt() async {
        await assertChange(of: .arabicInTranslation, from: "on", to: "off") {
            QuranContentStatePreferences.shared.showArabicInTranslation = false
        }
    }

    #if QURAN_SYNC
    func test_ayahIndicatorsChange_updatesIt() async {
        await assertChange(of: .ayahIndicators, from: "all", to: "reading_bookmark") {
            QuranContentStatePreferences.shared.ayahIndicatorVisibility = .readingBookmark
        }
    }
    #endif

    // MARK: App

    func test_appIconChange_updatesIt() async throws {
        await start()

        try await appIconService.set(primaryIcon)
        await settle()

        XCTAssertEqual(analytics.changes(of: .appIcon), ["blue", "navy"])
    }

    #if QURAN_SYNC
    func test_signingInAndOut_updatesIt() async throws {
        authenticationClient.authenticationStateValue = .notAuthenticated
        authenticationClient.authenticationStateAfterLogin = .authenticated
        await start()

        try await authenticationClient.login(on: UIViewController())
        await settle()
        try await authenticationClient.logout()
        await settle()

        XCTAssertEqual(analytics.changes(of: .syncSignedIn), ["no", "yes", "no"])
    }

    func test_sessionEndedOutsideTheClient_updatesItWhenTheAppBecomesActive() async {
        await start()

        authenticationClient.authenticationStateValue = .notAuthenticated
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await settle()

        XCTAssertEqual(analytics.changes(of: .syncSignedIn), ["yes", "no"])
    }
    #endif

    // MARK: Private

    private let primaryIcon = AppIconOption(
        id: "navy",
        alternateIconName: nil,
        name: "Navy",
        previewImageName: "app-icon-navy",
        accent: AppIconAccent(light: .systemIndigo, dark: .systemIndigo, onDark: .white)
    )
    private let blueIcon = AppIconOption(
        id: "blue",
        alternateIconName: "AppIcon-Blue",
        name: "Blue",
        previewImageName: "app-icon-blue",
        accent: AppIconAccent(light: .systemBlue, dark: .systemBlue, onDark: .black)
    )

    private var saved: SavedReporterPreferences!
    private var analytics: AnalyticsLibrarySpy!
    private var iconAccess: AlternateIconAccessFake!
    private var appIconService: AppIconService!
    private var sut: AnalyticsUserPropertiesReporter!
    private let reciters: [Reciter] = [.gappedReciter, .gaplessReciter]
    #if QURAN_SYNC
    private var authenticationClient: AuthenticationClientFake!
    private var notificationCenter: NotificationCenter!
    #endif

    private var expectedProperties: [String: String] {
        var properties: [AnalyticsUserProperty: String] = [
            .playbackRate: "1.25",
            .audioEnd: "hizb",
            .verseRepeat: "3",
            .rangeRepeat: "inf",
            .versePause: "0.5",
            .rangePause: "2.0",
            .audioStreaming: "on",
            .reciter: "afasy_gapless",
            .mushaf: "tajweed",
            .quranMode: "translation",
            .translationsCount: "2",
            .arabicFontSize: "xLarge",
            .translationFontSize: "small",
            .appearance: "dark",
            .themeStyle: "quiet",
            .wordPointer: "transliteration",
            .twoPages: "off",
            .arabicInTranslation: "on",
            .appIcon: "blue",
            .appLanguage: "en",
        ]
        #if QURAN_SYNC
        properties[.buildFlavor] = "sync"
        properties[.ayahIndicators] = "all"
        properties[.syncSignedIn] = "yes"
        #else
        properties[.buildFlavor] = "standard"
        #endif
        return Dictionary(uniqueKeysWithValues: properties.map { ($0.key.rawValue, $0.value) })
    }

    private func setKnownPreferences() {
        let audio = AudioPreferences.shared
        audio.playbackRate = 1.25
        audio.audioEnd = .hizb
        audio.verseRuns = .finite(3)
        audio.listRuns = .indefinite
        audio.verseDelay = .half
        audio.repetitionDelay = .twoSeconds
        audio.streamingEnabled = true
        ReciterPreferences.shared.lastSelectedReciterId = Reciter.gaplessReciter.id

        ReadingPreferences.shared.reading = .tajweed
        let content = QuranContentStatePreferences.shared
        content.quranMode = .translation
        content.twoPagesEnabled = false
        content.showArabicInTranslation = true
        #if QURAN_SYNC
        content.ayahIndicatorVisibility = .all
        #endif
        SelectedTranslationsPreferences.shared.selectedTranslationIds = [1, 2]
        FontSizePreferences.shared.arabicFontSize = .xLarge
        FontSizePreferences.shared.translationFontSize = .small
        ThemeService.shared.appearanceMode = .dark
        ThemeService.shared.themeStyle = .quiet
        WordTextPreferences.shared.isWordPointerActive = true
        WordTextPreferences.shared.wordTextType = .transliteration
    }

    private func makeReciterRetriever() -> ReciterDataRetriever {
        let bundle = SystemBundleFake()
        bundle.arrays = ["reciters.plist": reciters.map { $0.toPlistDictionary() } as NSArray]
        return ReciterDataRetriever(bundle: bundle)
    }

    private func makeSUT() -> AnalyticsUserPropertiesReporter {
        let catalog = AppIconCatalog(sections: [
            .init(id: "all", title: "All", previewSize: .large, options: [primaryIcon, blueIcon]),
        ])
        appIconService = AppIconService(catalog: catalog, iconAccess: iconAccess, bundle: SystemBundleFake())
        #if QURAN_SYNC
        return AnalyticsUserPropertiesReporter(
            analytics: analytics,
            appIconService: appIconService,
            reciterRetriever: makeReciterRetriever(),
            appLanguage: "en",
            authenticationClient: authenticationClient,
            notificationCenter: notificationCenter
        )
        #else
        return AnalyticsUserPropertiesReporter(
            analytics: analytics,
            appIconService: appIconService,
            reciterRetriever: makeReciterRetriever(),
            appLanguage: "en"
        )
        #endif
    }

    private func start() async {
        sut = makeSUT()
        sut.start()
        await settle()
    }

    private func settle() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        await sut.reciterUpdate?.value
        #if QURAN_SYNC
        await sut.syncSignedInUpdate?.value
        #endif
    }

    private func assertChange(
        of property: AnalyticsUserProperty,
        from initialValue: String,
        to newValue: String?,
        after change: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await start()

        change()
        await settle()

        XCTAssertEqual(analytics.changes(of: property), [initialValue, newValue], file: file, line: line)
        XCTAssertEqual(analytics.userProperty(property), newValue, file: file, line: line)
    }
}
