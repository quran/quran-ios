//
//  AnalyticsSetting.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import Analytics

/// A setting reported to analytics. Its name is the event parameter that carries its value.
enum AnalyticsSetting: String, CaseIterable {
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
    case dimOtherAyahs = "dim_other_ayahs"
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
    case footnotes
    case ayahIndicators = "ayah_indicators"

    // MARK: App

    case appIcon = "app_icon"
    case syncSignedIn = "sync_signed_in"
    case buildFlavor = "build_flavor"
    case appLanguage = "app_language"

    // MARK: Internal

    enum Area: String, CaseIterable {
        case audio
        case reading
        case app

        // MARK: Internal

        /// The event that carries the area's current values.
        var snapshotEvent: String {
            "settings_\(rawValue)"
        }
    }

    var area: Area {
        switch self {
        case .playbackRate, .audioEnd, .verseRepeat, .rangeRepeat, .versePause, .rangePause, .audioStreaming,
             .dimOtherAyahs, .reciter:
            .audio
        case .mushaf, .quranMode, .translationsCount, .arabicFontSize, .translationFontSize, .appearance, .themeStyle,
             .wordPointer, .twoPages, .arabicInTranslation, .footnotes, .ayahIndicators:
            .reading
        case .appIcon, .syncSignedIn, .buildFlavor, .appLanguage:
            .app
        }
    }

    /// Whether a change logs `setting_changed`.
    var logsChanges: Bool {
        switch self {
        // The user can't change them while the app runs.
        case .buildFlavor, .appLanguage: false
        // Their own events report changes: `ChangeAppIcon*` and `QuranSyncSignIn`/`QuranSyncSignOut`.
        case .appIcon, .syncSignedIn: false
        default: true
        }
    }
}

extension AnalyticsLibrary {
    func settingChanged(_ setting: AnalyticsSetting, to value: String?) {
        var parameters: [String: AnalyticsValue] = ["setting": .string(setting.rawValue)]
        parameters["value"] = value.map(AnalyticsValue.string)
        logEvent("setting_changed", parameters: parameters)
    }

    /// Logs one event per area, omitting settings without a value.
    func settingsSnapshot(_ values: [AnalyticsSetting: String]) {
        for area in AnalyticsSetting.Area.allCases {
            let parameters = values
                .filter { $0.key.area == area }
                .reduce(into: [String: AnalyticsValue]()) { $0[$1.key.rawValue] = .string($1.value) }
            logEvent(area.snapshotEvent, parameters: parameters)
        }
    }
}
