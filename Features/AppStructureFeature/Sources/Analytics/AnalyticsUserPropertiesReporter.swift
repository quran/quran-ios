//
//  AnalyticsUserPropertiesReporter.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
#if QURAN_SYNC
import AuthenticationClient
#endif
import Combine
import Foundation
import NoorUI
import QuranAudioKit
import QuranTextKit
import ReadingService
import ReciterService
import TranslationService
import UIKit
import VLogging
import WordTextService

@MainActor
final class AnalyticsUserPropertiesReporter {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        analytics: AnalyticsLibrary,
        appIconService: AppIconService,
        reciterRetriever: ReciterDataRetriever,
        appLanguage: String?,
        authenticationClient: any AuthenticationClient,
        notificationCenter: NotificationCenter = .default
    ) {
        self.analytics = analytics
        self.appIconService = appIconService
        self.reciterRetriever = reciterRetriever
        self.appLanguage = appLanguage
        self.authenticationClient = authenticationClient
        self.notificationCenter = notificationCenter
    }
    #else
    init(
        analytics: AnalyticsLibrary,
        appIconService: AppIconService,
        reciterRetriever: ReciterDataRetriever,
        appLanguage: String?
    ) {
        self.analytics = analytics
        self.appIconService = appIconService
        self.reciterRetriever = reciterRetriever
        self.appLanguage = appLanguage
    }
    #endif

    // MARK: Internal

    // Exposed for tests to await.
    private(set) var reciterUpdate: Task<Void, Never>?
    #if QURAN_SYNC
    private(set) var syncSignedInUpdate: Task<Void, Never>?
    #endif

    func start() {
        logger.info("Analytics: reporting user properties")

        reportApp()
        reportAudio()
        reportReading()
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let appIconService: AppIconService
    private let reciterRetriever: ReciterDataRetriever
    private let appLanguage: String?
    #if QURAN_SYNC
    private let authenticationClient: any AuthenticationClient
    private let notificationCenter: NotificationCenter
    #endif

    private var cancellables: Set<AnyCancellable> = []
    private var reportedValues: [AnalyticsUserProperty: String?] = [:]
    private var reciterId: Int?

    // MARK: App

    private func reportApp() {
        #if QURAN_SYNC
        set("sync", for: .buildFlavor)
        #else
        set("standard", for: .buildFlavor)
        #endif
        set(appLanguage.map(AnalyticsUserPropertyValue.limited), for: .appLanguage)

        appIconService.currentOptionPublisher
            .sink { [weak self] option in
                self?.set(AnalyticsUserPropertyValue.limited(option.id), for: .appIcon)
            }
            .store(in: &cancellables)

        #if QURAN_SYNC
        authenticationClient.authenticationStateChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.setSyncSignedIn(state) }
            .store(in: &cancellables)
        // A session the server ends doesn't notify the client.
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.readSyncSignedIn() }
            .store(in: &cancellables)
        readSyncSignedIn()
        #endif
    }

    #if QURAN_SYNC
    private func readSyncSignedIn() {
        syncSignedInUpdate?.cancel()
        syncSignedInUpdate = Task { [weak self, authenticationClient] in
            let state = await authenticationClient.authenticationState
            guard !Task.isCancelled else { return }
            self?.set(AnalyticsUserPropertyValue.yesNo(state == .authenticated), for: .syncSignedIn)
        }
    }

    private func setSyncSignedIn(_ state: AuthenticationState) {
        syncSignedInUpdate?.cancel()
        set(AnalyticsUserPropertyValue.yesNo(state == .authenticated), for: .syncSignedIn)
    }
    #endif

    // MARK: Audio

    private func reportAudio() {
        let audio = AudioPreferences.shared
        observe(.playbackRate, changes: audio.$playbackRate) {
            AnalyticsUserPropertyValue.playbackRate(audio.playbackRate)
        }
        observe(.audioEnd, changes: audio.$audioEnd) {
            AnalyticsUserPropertyValue.audioEnd(audio.audioEnd)
        }
        observe(.verseRepeat, changes: audio.$verseRuns) {
            AnalyticsUserPropertyValue.runs(audio.verseRuns)
        }
        observe(.rangeRepeat, changes: audio.$listRuns) {
            AnalyticsUserPropertyValue.runs(audio.listRuns)
        }
        observe(.versePause, changes: audio.$verseDelay) {
            AnalyticsUserPropertyValue.verseDelay(audio.verseDelay)
        }
        observe(.rangePause, changes: audio.$repetitionDelay) {
            AnalyticsUserPropertyValue.repetitionDelay(audio.repetitionDelay)
        }
        observe(.audioStreaming, changes: audio.$streamingEnabled) {
            AnalyticsUserPropertyValue.onOff(audio.streamingEnabled)
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
            self?.set(reciter.map { AnalyticsUserPropertyValue.reciter(nameKey: $0.nameKey) }, for: .reciter)
        }
    }

    // MARK: Reading

    private func reportReading() {
        let reading = ReadingPreferences.shared
        observe(.mushaf, changes: reading.$reading) {
            AnalyticsUserPropertyValue.mushaf(reading.reading)
        }

        let content = QuranContentStatePreferences.shared
        observe(.quranMode, changes: content.$quranMode) {
            AnalyticsUserPropertyValue.quranMode(content.quranMode)
        }
        observe(.twoPages, changes: content.$twoPagesEnabled) {
            AnalyticsUserPropertyValue.onOff(content.twoPagesEnabled)
        }
        observe(.arabicInTranslation, changes: content.$showArabicInTranslation) {
            AnalyticsUserPropertyValue.onOff(content.showArabicInTranslation)
        }
        #if QURAN_SYNC
        observe(.ayahIndicators, changes: content.$ayahIndicatorVisibility) {
            AnalyticsUserPropertyValue.ayahIndicators(content.ayahIndicatorVisibility)
        }
        #endif

        let translations = SelectedTranslationsPreferences.shared
        observe(.translationsCount, changes: translations.$selectedTranslationIds) {
            AnalyticsUserPropertyValue.countBucket(translations.selectedTranslationIds.count)
        }

        let fontSizes = FontSizePreferences.shared
        observe(.arabicFontSize, changes: fontSizes.$arabicFontSize) {
            AnalyticsUserPropertyValue.fontSize(fontSizes.arabicFontSize)
        }
        observe(.translationFontSize, changes: fontSizes.$translationFontSize) {
            AnalyticsUserPropertyValue.fontSize(fontSizes.translationFontSize)
        }

        let theme = ThemeService.shared
        observe(.appearance, changes: theme.appearanceModePublisher) {
            AnalyticsUserPropertyValue.appearance(theme.appearanceMode)
        }
        observe(.themeStyle, changes: theme.themeStylePublisher) {
            AnalyticsUserPropertyValue.themeStyle(theme.themeStyle)
        }

        let words = WordTextPreferences.shared
        let wordPointerChanges = Publishers.Merge(
            words.$isWordPointerActive.map { _ in () },
            words.$wordTextType.map { _ in () }
        )
        observe(.wordPointer, changes: wordPointerChanges) {
            AnalyticsUserPropertyValue.wordPointer(isActive: words.isWordPointerActive, textType: words.wordTextType)
        }
    }

    // MARK: Reporting

    private func observe<Changes: Publisher>(
        _ property: AnalyticsUserProperty,
        changes: Changes,
        value: @escaping () -> String?
    ) where Changes.Failure == Never {
        changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.set(value(), for: property) }
            .store(in: &cancellables)
        set(value(), for: property)
    }

    private func set(_ value: String?, for property: AnalyticsUserProperty) {
        if let reportedValue = reportedValues[property], reportedValue == value {
            return
        }
        reportedValues[property] = .some(value)
        analytics.setUserProperty(value, for: property)
    }
}
