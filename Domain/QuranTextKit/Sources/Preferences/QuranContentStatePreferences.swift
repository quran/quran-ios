//
//  QuranContentStatePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-11-24.
//

import Preferences
import QuranText

public struct QuranContentStatePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = QuranContentStatePreferences()

    @TransformedPreference(showQuranTranslationView, transformer: quranModeTransfomer)
    public var quranMode: QuranMode

    @Preference(twoPagesEnabled)
    public var twoPagesEnabled: Bool

    @Preference(verticalScrollingEnabled)
    public var verticalScrollingEnabled: Bool

    @Preference(focusModeEnabled)
    public var focusModeEnabled: Bool

    @Preference(showLinePageDividers)
    public var showLinePageDividers: Bool

    @Preference(showLinePageSidelines)
    public var showLinePageSidelines: Bool

    @Preference(showArabicInTranslation)
    public var showArabicInTranslation: Bool

    #if QURAN_SYNC
    @TransformedPreference(ayahIndicatorVisibility, transformer: .rawRepresentable(defaultValue: .readingBookmark))
    public var ayahIndicatorVisibility: AyahIndicatorVisibility
    #endif

    // MARK: Private

    private static let showQuranTranslationView = PreferenceKey<Bool>(key: "showQuranTranslationView", defaultValue: false)
    private static let twoPagesEnabled = PreferenceKey<Bool>(key: "twoPagesEnabled", defaultValue: TwoPagesUtils.settingDefaultValue)
    private static let verticalScrollingEnabled = PreferenceKey<Bool>(key: "verticalScrollingEnabled", defaultValue: false)
    private static let focusModeEnabled = PreferenceKey<Bool>(key: "focusModeEnabled", defaultValue: false)
    private static let showLinePageDividers = PreferenceKey<Bool>(key: "showLinePageDividers", defaultValue: true)
    private static let showLinePageSidelines = PreferenceKey<Bool>(key: "showLinePageSidelines", defaultValue: true)
    private static let showArabicInTranslation = PreferenceKey<Bool>(key: "showArabicInTranslation", defaultValue: true)
    #if QURAN_SYNC
    private static let ayahIndicatorVisibility = PreferenceKey<String>(key: "ayahIndicators", defaultValue: AyahIndicatorVisibility.readingBookmark.rawValue)
    #endif

    private static let quranModeTransfomer = PreferenceTransformer<Bool, QuranMode>(
        rawToValue: { $0 ? .translation : .arabic },
        valueToRaw: { $0 == .translation }
    )
}
