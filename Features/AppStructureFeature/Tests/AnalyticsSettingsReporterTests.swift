//
//  AnalyticsSettingsReporterTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import AnalyticsFake
#if QURAN_SYNC
import AuthenticationClientFake
import MobileSync
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

/// Per-setting changes and the signed-in user ID are covered in this class's extensions.
@MainActor
final class AnalyticsSettingsReporterTests: XCTestCase {
    // MARK: Internal

    var analytics: AnalyticsLibrarySpy!
    var time: SystemTimeFake!
    var notificationCenter: NotificationCenter!
    var sut: AnalyticsSettingsReporter!
    #if QURAN_SYNC
    var authenticationClient: AuthenticationClientFake!
    #endif

    var changeEvents: [[String: AnalyticsValue]] {
        analytics.parameterizedEvents(named: "setting_changed")
    }

    var snapshotEvents: [AnalyticsLibrarySpy.ParameterizedEvent] {
        analytics.parameterizedEvents.filter { $0.name.hasPrefix("settings_") }
    }

    override func setUp() async throws {
        try await super.setUp()
        saved = SavedReporterPreferences()
        analytics = AnalyticsLibrarySpy()
        time = SystemTimeFake()
        time.now = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: 9)))
        notificationCenter = NotificationCenter()
        iconAccess = AlternateIconAccessFake(alternateIconName: "AppIcon-Blue")
        #if QURAN_SYNC
        authenticationClient = AuthenticationClientFake()
        authenticationClient.authenticationStateValue = .authenticated
        #endif
        AnalyticsSettingsPreferences.shared.lastSnapshotDate = nil
        setKnownPreferences()
    }

    override func tearDown() async throws {
        #if QURAN_SYNC
        sut?.userIDObservation?.cancel()
        #endif
        sut = nil
        saved.restore()
        AppIconAccent.setCurrent(nil)
        try await super.tearDown()
    }

    // MARK: Snapshot

    func test_start_logsTheSnapshotByArea() async {
        await start()

        XCTAssertEqual(analytics.parameterizedEvents, expectedSnapshot)
    }

    func test_unavailableReciter_snapshotsTheFirstReciterLikePlayback() async throws {
        let retrievedReciters = await makeReciterRetriever().getReciters()
        let firstReciter = try XCTUnwrap(retrievedReciters.first)
        ReciterPreferences.shared.lastSelectedReciterId = 999

        await start()

        let audio = snapshotEvents.first { $0.name == "settings_audio" }
        XCTAssertEqual(audio?.parameters["reciter"], .string(AnalyticsSettingValue.reciter(nameKey: firstReciter.nameKey)))
    }

    func test_twoPagesNeverChosen_snapshotsOn() async {
        // People who never chose have no stored value. The key is private to QuranTextKit, so it's repeated here.
        UserDefaults.standard.removeObject(forKey: "twoPagesEnabled")

        await start()

        let reading = snapshotEvents.first { $0.name == "settings_reading" }
        XCTAssertEqual(reading?.parameters["two_pages"], .string("on"))
    }

    func test_relaunchOnTheSameDay_doesNotLogTheSnapshotAgain() async {
        await start()

        await start()

        XCTAssertEqual(snapshotEvents, expectedSnapshot)
    }

    func test_becomingActiveOnTheSameDay_doesNotLogTheSnapshotAgain() async {
        await start()

        time.now.addTimeInterval(60 * 60)
        await becomeActive()

        XCTAssertEqual(snapshotEvents, expectedSnapshot)
    }

    func test_becomingActiveOnANewDay_logsTheSnapshotAgain() async throws {
        await start()

        time.now = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: time.now))
        await becomeActive()

        XCTAssertEqual(snapshotEvents, expectedSnapshot + expectedSnapshot)
    }

    #if QURAN_SYNC
    func test_sessionEndedOutsideTheClient_isInTheNextSnapshot() async throws {
        await start()

        authenticationClient.authenticationStateValue = .notAuthenticated
        time.now = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: time.now))
        await becomeActive()

        let app = snapshotEvents.last { $0.name == "settings_app" }
        XCTAssertEqual(app?.parameters["sync_signed_in"], .string("no"))
    }

    func test_signedInLaunch_snapshotsSignedInOnceTheStoredSessionIsRead() async {
        await startWhileReadingTheStoredSession()

        authenticationClient.authenticationStateValue = .authenticated
        authenticationClient.loggedInUserValue = MobileSyncUser(id: "user-1")
        await settle()

        let app = snapshotEvents.first { $0.name == "settings_app" }
        XCTAssertEqual(app?.parameters["sync_signed_in"], .string("yes"))
    }
    #endif

    // MARK: Changes

    func test_change_logsItOnce() async {
        await start()

        AudioPreferences.shared.playbackRate = 2
        await settle()
        AudioPreferences.shared.playbackRate = 2
        await settle()

        XCTAssertEqual(changeEvents, [changed("playback_rate", to: "2.0")])
    }

    func test_changeFromAnotherThread_logsIt() async {
        await start()

        await Task.detached {
            AudioPreferences.shared.audioEnd = .quran
        }.value
        await settle()

        XCTAssertEqual(changeEvents, [changed("audio_end", to: "quran")])
    }

    func test_appIconChange_isNotLogged() async throws {
        await start()

        try await appIconService.set(primaryIcon)
        await settle()

        XCTAssertEqual(changeEvents, [])
    }

    #if QURAN_SYNC
    func test_signingInAndOut_isNotLogged() async throws {
        authenticationClient.authenticationStateValue = .notAuthenticated
        authenticationClient.authenticationStateAfterLogin = .authenticated
        await start()

        try await authenticationClient.login(on: UIViewController())
        await settle()
        try await authenticationClient.logout()
        await settle()

        XCTAssertEqual(changeEvents, [])
    }
    #endif

    // MARK: Legacy user properties

    func test_start_clearsTheLegacyUserProperties() async {
        await start()

        XCTAssertEqual(
            analytics.userPropertyChanges.sorted { $0.name < $1.name },
            legacyUserProperties.sorted().map { .init(name: $0, value: nil) }
        )
    }

    // MARK: Helpers

    func changed(_ setting: String, to value: String) -> [String: AnalyticsValue] {
        ["setting": .string(setting), "value": .string(value)]
    }

    func start() async {
        #if QURAN_SYNC
        sut?.userIDObservation?.cancel()
        #endif
        sut = makeSUT()
        sut.start()
        await settle()
    }

    #if QURAN_SYNC
    /// Starts while MobileSync reads the stored session, reporting signed out meanwhile. It can't settle, since
    /// the sign-in lookup waits for the session, so it waits for the reciter lookup instead.
    func startWhileReadingTheStoredSession() async {
        authenticationClient = AuthenticationClientFake(restoringSession: true)
        authenticationClient.authenticationStateValue = .notAuthenticated
        sut = makeSUT()
        sut.start()
        await sut.reciterUpdate?.value
    }
    #endif

    func settle() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        await sut.reciterUpdate?.value
        #if QURAN_SYNC
        await sut.syncSignedInUpdate?.value
        #endif
        await sut.snapshotUpdate?.value
    }

    /// Starts reporting, changes a setting, and checks that only that change is logged.
    func assertChange(
        of setting: String,
        to value: String,
        after change: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await start()

        change()
        await settle()

        XCTAssertEqual(changeEvents, [changed(setting, to: value)], file: file, line: line)
    }

    // MARK: Private

    private let primaryIcon = AppIconOption(
        id: "navy",
        alternateIconName: nil,
        name: "Navy",
        previewImageName: "app-icon-navy",
        artworkImageName: "app-artwork-navy",
        accent: AppIconAccent(light: .systemIndigo, dark: .systemIndigo, onDark: .white)
    )
    private let blueIcon = AppIconOption(
        id: "blue",
        alternateIconName: "AppIcon-Blue",
        name: "Blue",
        previewImageName: "app-icon-blue",
        artworkImageName: "app-artwork-blue",
        accent: AppIconAccent(light: .systemBlue, dark: .systemBlue, onDark: .black)
    )
    private let reciters: [Reciter] = [.gappedReciter, .gaplessReciter]
    private let legacyUserProperties = [
        "playback_rate", "audio_end", "verse_repeat", "range_repeat", "verse_pause", "range_pause",
        "audio_streaming", "dim_other_ayahs", "reciter", "mushaf", "quran_mode", "translations_count",
        "arabic_font_size", "trans_font_size", "appearance", "theme_style", "word_pointer", "two_pages",
        "arabic_in_trans", "ayah_indicators", "app_icon", "sync_signed_in", "build_flavor", "app_language",
    ]

    private var saved: SavedReporterPreferences!
    private var iconAccess: AlternateIconAccessFake!
    private var appIconService: AppIconService!

    private var expectedSnapshot: [AnalyticsLibrarySpy.ParameterizedEvent] {
        let audio: [String: String] = [
            "playback_rate": "1.25",
            "audio_end": "hizb",
            "verse_repeat": "3",
            "range_repeat": "inf",
            "verse_pause": "0.5",
            "range_pause": "2.0",
            "audio_streaming": "on",
            "dim_other_ayahs": "on",
            "reciter": "afasy_gapless",
        ]
        var reading: [String: String] = [
            "mushaf": "tajweed",
            "quran_mode": "translation",
            "translations_count": "2",
            "arabic_font_size": "xLarge",
            "trans_font_size": "small",
            "appearance": "dark",
            "theme_style": "quiet",
            "word_pointer": "transliteration",
            "two_pages": "off",
            "arabic_in_trans": "on",
            "footnotes": "on",
        ]
        var app: [String: String] = [
            "app_icon": "blue",
            "app_language": "en",
        ]
        #if QURAN_SYNC
        reading["ayah_indicators"] = "all"
        app["build_flavor"] = "sync"
        app["sync_signed_in"] = "yes"
        #else
        app["build_flavor"] = "standard"
        #endif
        return [("settings_audio", audio), ("settings_reading", reading), ("settings_app", app)].map { name, values in
            .init(name: name, parameters: values.mapValues(AnalyticsValue.string))
        }
    }

    private func becomeActive() async {
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await settle()
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
        content.showFootnotesInTranslation = true
        content.dimsOtherAyahs = true
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

    private func makeSUT() -> AnalyticsSettingsReporter {
        let catalog = AppIconCatalog(sections: [
            .init(id: "all", title: "All", previewSize: .large, options: [primaryIcon, blueIcon]),
        ])
        appIconService = AppIconService(catalog: catalog, iconAccess: iconAccess, bundle: SystemBundleFake())
        #if QURAN_SYNC
        return AnalyticsSettingsReporter(
            analytics: analytics,
            appIconService: appIconService,
            reciterRetriever: makeReciterRetriever(),
            appLanguage: "en",
            time: time,
            authenticationClient: authenticationClient,
            notificationCenter: notificationCenter
        )
        #else
        return AnalyticsSettingsReporter(
            analytics: analytics,
            appIconService: appIconService,
            reciterRetriever: makeReciterRetriever(),
            appLanguage: "en",
            time: time,
            notificationCenter: notificationCenter
        )
        #endif
    }
}
