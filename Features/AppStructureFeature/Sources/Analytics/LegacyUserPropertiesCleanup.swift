//
//  LegacyUserPropertiesCleanup.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import Analytics

/// Clears the user properties internal builds set. Firebase keeps them on the device and sends them with
/// every event until they're cleared.
enum LegacyUserPropertiesCleanup {
    // MARK: Internal

    // Temporary: remove this cleanup, with `AnalyticsLibrary.setUserProperty(_:forName:)`, before release.
    static func run(analytics: AnalyticsLibrary) {
        for name in names {
            analytics.setUserProperty(nil, forName: name)
        }
    }

    // MARK: Private

    private static let names = [
        "playback_rate",
        "audio_end",
        "verse_repeat",
        "range_repeat",
        "verse_pause",
        "range_pause",
        "audio_streaming",
        "dim_other_ayahs",
        "reciter",
        "mushaf",
        "quran_mode",
        "translations_count",
        "arabic_font_size",
        "trans_font_size",
        "appearance",
        "theme_style",
        "word_pointer",
        "two_pages",
        "arabic_in_trans",
        "ayah_indicators",
        "app_icon",
        "sync_signed_in",
        "build_flavor",
        "app_language",
    ]
}
