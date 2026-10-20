//
//  AnalyticsUserProperty.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

public enum AnalyticsUserProperty: String, CaseIterable, Sendable {
    // MARK: Audio

    case playbackRate = "playback_rate"
    case audioEnd = "audio_end"
    case verseRepeat = "verse_repeat"
    case rangeRepeat = "range_repeat"
    /// The pause after each verse, as a multiple of the verse's duration: `0.0` … `2.0`.
    case versePause = "verse_pause"
    /// The pause before the range repeats, in seconds: `0.0` … `10.0`.
    case rangePause = "range_pause"
    case audioStreaming = "audio_streaming"
    case reciter

    // MARK: Reading

    case mushaf
    case quranMode = "quran_mode"
    case translationsCount = "translations_count"
    case arabicFontSize = "arabic_font_size"
    case translationFontSize = "trans_font_size"
    case appearance
    case themeStyle = "theme_style"
    case wordPointer = "word_pointer"
    case twoPages = "two_pages"
    case arabicInTranslation = "arabic_in_trans"
    case ayahIndicators = "ayah_indicators"

    // MARK: App

    case appIcon = "app_icon"
    case syncSignedIn = "sync_signed_in"
    case buildFlavor = "build_flavor"
    case appLanguage = "app_language"

    // MARK: Public

    public static let maxNameLength = 24
}
