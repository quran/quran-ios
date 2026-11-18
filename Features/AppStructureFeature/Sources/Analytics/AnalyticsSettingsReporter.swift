//
//  AnalyticsSettingsReporter.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
#if QURAN_SYNC
import AuthenticationClient
import MobileSync
#endif
import Combine
import Foundation
import NoorUI
import QuranAudioKit
import QuranTextKit
import ReadingService
import ReciterService
import SystemDependencies
import TranslationService
import UIKit
import VLogging
import WordTextService

/// Logs `setting_changed` when a setting changes, and the current settings once a day.
@MainActor
final class AnalyticsSettingsReporter {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        analytics: AnalyticsLibrary,
        appIconService: AppIconService,
        reciterRetriever: ReciterDataRetriever,
        appLanguage: String?,
        time: SystemTime,
        authenticationClient: any AuthenticationClient,
        notificationCenter: NotificationCenter = .default
    ) {
        self.analytics = analytics
        self.appIconService = appIconService
        self.reciterRetriever = reciterRetriever
        self.appLanguage = appLanguage
        self.time = time
        self.authenticationClient = authenticationClient
        self.notificationCenter = notificationCenter
    }
    #else
    init(
        analytics: AnalyticsLibrary,
        appIconService: AppIconService,
        reciterRetriever: ReciterDataRetriever,
        appLanguage: String?,
        time: SystemTime,
        notificationCenter: NotificationCenter = .default
    ) {
        self.analytics = analytics
        self.appIconService = appIconService
        self.reciterRetriever = reciterRetriever
        self.appLanguage = appLanguage
        self.time = time
        self.notificationCenter = notificationCenter
    }
    #endif

    // MARK: Internal

    // Exposed for tests to await.
    private(set) var reciterUpdate: Task<Void, Never>?
    private(set) var snapshotUpdate: Task<Void, Never>?
    #if QURAN_SYNC
    private(set) var syncSignedInUpdate: Task<Void, Never>?
    /// Follows the signed-in user; cancel it to stop. `LaunchStartup` keeps the reporter for the app's lifetime,
    /// so nothing cancels it on deinit.
    private(set) var userIDObservation: Task<Void, Never>?
    #endif

    func start() {
        logger.info("Analytics: reporting settings")
        LegacyUserPropertiesCleanup.run(analytics: analytics)

        reportApp()
        reportAudio()
        reportReading()
        #if QURAN_SYNC
        observeUserID()
        #endif

        logSnapshotIfDue()
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.becameActive() }
            .store(in: &cancellables)
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let appIconService: AppIconService
    private let reciterRetriever: ReciterDataRetriever
    private let appLanguage: String?
    private let time: SystemTime
    private let notificationCenter: NotificationCenter
    private let preferences = AnalyticsSettingsPreferences.shared
    #if QURAN_SYNC
    private let authenticationClient: any AuthenticationClient
    #endif

    private var cancellables: Set<AnyCancellable> = []
    /// Every setting's latest value, nil for none.
    private var values: [AnalyticsSetting: String?] = [:]
    private var reciterId: Int?
    #if QURAN_SYNC
    /// `.none` until the first user ID is sent.
    private var reportedUserID: String??
    #endif

    // MARK: App

    private func reportApp() {
        #if QURAN_SYNC
        set("sync", for: .buildFlavor)
        #else
        set("standard", for: .buildFlavor)
        #endif
        set(appLanguage.map(AnalyticsSettingValue.limited), for: .appLanguage)

        appIconService.currentOptionPublisher
            .sink { [weak self] option in
                self?.set(AnalyticsSettingValue.limited(option.id), for: .appIcon)
            }
            .store(in: &cancellables)

        #if QURAN_SYNC
        authenticationClient.authenticationStateChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.setSyncSignedIn(state) }
            .store(in: &cancellables)
        readSyncSignedIn()
        #endif
    }

    #if QURAN_SYNC
    private func readSyncSignedIn() {
        syncSignedInUpdate?.cancel()
        syncSignedInUpdate = Task { [weak self, authenticationClient] in
            // At launch the state reads signed out until MobileSync has read the stored session, which the
            // first user update waits for.
            _ = try? await authenticationClient.loggedInUserUpdates.first { _ in true }
            let state = await authenticationClient.authenticationState
            guard !Task.isCancelled else { return }
            self?.set(AnalyticsSettingValue.yesNo(state == .authenticated), for: .syncSignedIn)
        }
    }

    private func setSyncSignedIn(_ state: AuthenticationState) {
        syncSignedInUpdate?.cancel()
        set(AnalyticsSettingValue.yesNo(state == .authenticated), for: .syncSignedIn)
        if state == .authenticated {
            // Recovers the user ID if the observation ended with an error.
            observeUserID()
        } else {
            setUserID(nil)
        }
    }

    // MARK: User ID

    /// Ties analytics to the Quran.com account while signed in. Crash reports never get it.
    private func observeUserID() {
        userIDObservation?.cancel()
        userIDObservation = Task { [weak self, authenticationClient] in
            do {
                for try await user in authenticationClient.loggedInUserUpdates {
                    let state = await authenticationClient.authenticationState
                    guard !Task.isCancelled, let self else { return }
                    updateUserID(user, state: state)
                }
            } catch is CancellationError {
                return
            } catch {
                logger.error("Analytics: failed to observe the signed-in user: \(error)")
            }
        }
    }

    /// A nil user is also a signed-in session whose profile isn't known yet, so only the state clears the ID.
    private func updateUserID(_ user: MobileSyncUser?, state: AuthenticationState) {
        guard state == .authenticated else {
            setUserID(nil)
            return
        }
        if let user {
            setUserID(user.id)
        }
    }

    private func setUserID(_ userID: String?) {
        if let reportedUserID, reportedUserID == userID {
            return
        }
        reportedUserID = .some(userID)
        // Never log the ID: logs reach crash reports, which stay anonymous.
        logger.info("Analytics: \(userID == nil ? "cleared" : "set") the user ID")
        analytics.setUserID(userID)
    }
    #endif

    // MARK: Audio

    private func reportAudio() {
        let audio = AudioPreferences.shared
        observe(.playbackRate, changes: audio.$playbackRate) {
            AnalyticsSettingValue.playbackRate(audio.playbackRate)
        }
        observe(.audioEnd, changes: audio.$audioEnd) {
            AnalyticsSettingValue.audioEnd(audio.audioEnd)
        }
        observe(.verseRepeat, changes: audio.$verseRuns) {
            AnalyticsSettingValue.runs(audio.verseRuns)
        }
        observe(.rangeRepeat, changes: audio.$listRuns) {
            AnalyticsSettingValue.runs(audio.listRuns)
        }
        observe(.versePause, changes: audio.$verseDelay) {
            AnalyticsSettingValue.verseDelay(audio.verseDelay)
        }
        observe(.rangePause, changes: audio.$repetitionDelay) {
            AnalyticsSettingValue.repetitionDelay(audio.repetitionDelay)
        }
        observe(.audioStreaming, changes: audio.$streamingEnabled) {
            AnalyticsSettingValue.onOff(audio.streamingEnabled)
        }
        let content = QuranContentStatePreferences.shared
        observe(.dimOtherAyahs, changes: content.$dimsOtherAyahs) {
            AnalyticsSettingValue.onOff(content.dimsOtherAyahs)
        }

        ReciterPreferences.shared.$lastSelectedReciterId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateReciter() }
            .store(in: &cancellables)
        updateReciter()
    }

    private func updateReciter() {
        let id = ReciterPreferences.shared.lastSelectedReciterId
        guard id != reciterId else { return }
        reciterId = id

        reciterUpdate?.cancel()
        reciterUpdate = Task { [weak self, reciterRetriever] in
            let reciters = await reciterRetriever.getReciters()
            guard !Task.isCancelled else { return }
            // Playback falls back to the first reciter when the selected one is unavailable.
            let reciter = reciters.first { $0.id == id } ?? reciters.first
            self?.set(reciter.map { AnalyticsSettingValue.reciter(nameKey: $0.nameKey) }, for: .reciter)
        }
    }

    // MARK: Reading

    private func reportReading() {
        let reading = ReadingPreferences.shared
        observe(.mushaf, changes: reading.$reading) {
            AnalyticsSettingValue.mushaf(reading.reading)
        }

        let content = QuranContentStatePreferences.shared
        observe(.quranMode, changes: content.$quranMode) {
            AnalyticsSettingValue.quranMode(content.quranMode)
        }
        observe(.twoPages, changes: content.$twoPagesEnabled) {
            content.twoPagesEnabled.map(AnalyticsSettingValue.onOff) ?? AnalyticsSettingValue.notChosen
        }
        observe(.arabicInTranslation, changes: content.$showArabicInTranslation) {
            AnalyticsSettingValue.onOff(content.showArabicInTranslation)
        }
        observe(.footnotes, changes: content.$showFootnotesInTranslation) {
            AnalyticsSettingValue.onOff(content.showFootnotesInTranslation)
        }
        #if QURAN_SYNC
        observe(.ayahIndicators, changes: content.$ayahIndicatorVisibility) {
            AnalyticsSettingValue.ayahIndicators(content.ayahIndicatorVisibility)
        }
        #endif

        let translations = SelectedTranslationsPreferences.shared
        observe(.translationsCount, changes: translations.$selectedTranslationIds) {
            AnalyticsSettingValue.countBucket(translations.selectedTranslationIds.count)
        }

        let fontSizes = FontSizePreferences.shared
        observe(.arabicFontSize, changes: fontSizes.$arabicFontSize) {
            AnalyticsSettingValue.fontSize(fontSizes.arabicFontSize)
        }
        observe(.translationFontSize, changes: fontSizes.$translationFontSize) {
            AnalyticsSettingValue.fontSize(fontSizes.translationFontSize)
        }

        let theme = ThemeService.shared
        observe(.appearance, changes: theme.appearanceModePublisher) {
            AnalyticsSettingValue.appearance(theme.appearanceMode)
        }
        observe(.themeStyle, changes: theme.themeStylePublisher) {
            AnalyticsSettingValue.themeStyle(theme.themeStyle)
        }

        let words = WordTextPreferences.shared
        let wordPointerChanges = Publishers.Merge(
            words.$isWordPointerActive.map { _ in () },
            words.$wordTextType.map { _ in () }
        )
        observe(.wordPointer, changes: wordPointerChanges) {
            AnalyticsSettingValue.wordPointer(isActive: words.isWordPointerActive, textType: words.wordTextType)
        }
    }

    // MARK: Snapshot

    private func becameActive() {
        #if QURAN_SYNC
        // A session the server ends doesn't notify the client.
        readSyncSignedIn()
        #endif
        logSnapshotIfDue()
    }

    /// Logs the snapshot unless one was logged today, after any earlier snapshot and once every value is known.
    private func logSnapshotIfDue() {
        snapshotUpdate = Task { [weak self, previous = snapshotUpdate] in
            await previous?.value
            await self?.waitForLookups()
            self?.logSnapshotUnlessLoggedToday()
        }
    }

    /// Waits for the reciter and sign-in lookups, including any that replaces one meanwhile.
    private func waitForLookups() async {
        var awaited: Set<Task<Void, Never>> = []
        while let lookup = lookups.first(where: { !awaited.contains($0) }) {
            await lookup.value
            awaited.insert(lookup)
        }
    }

    private var lookups: [Task<Void, Never>] {
        #if QURAN_SYNC
        [reciterUpdate, syncSignedInUpdate].compactMap { $0 }
        #else
        [reciterUpdate].compactMap { $0 }
        #endif
    }

    private func logSnapshotUnlessLoggedToday() {
        let now = time.now
        if let lastDate = preferences.lastSnapshotDate, Calendar.current.isDate(lastDate, inSameDayAs: now) {
            return
        }
        preferences.lastSnapshotDate = now
        logger.info("Analytics: logging the settings snapshot")
        analytics.settingsSnapshot(values.compactMapValues { $0 })
    }

    // MARK: Reporting

    private func observe<Changes: Publisher>(
        _ setting: AnalyticsSetting,
        changes: Changes,
        value: @escaping () -> String?
    ) where Changes.Failure == Never {
        changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.set(value(), for: setting) }
            .store(in: &cancellables)
        set(value(), for: setting)
    }

    /// Records the first value silently: the snapshot reports it.
    private func set(_ value: String?, for setting: AnalyticsSetting) {
        guard let reportedValue = values[setting] else {
            values[setting] = .some(value)
            return
        }
        guard reportedValue != value else {
            return
        }
        values[setting] = .some(value)
        if setting.logsChanges {
            analytics.settingChanged(setting, to: value)
        }
    }
}
