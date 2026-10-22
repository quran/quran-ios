//
//  SavedReporterPreferences.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation
import NoorUI

/// Puts back the shared user defaults the reporter reads, removing keys that were missing.
@MainActor
struct SavedReporterPreferences {
    // MARK: Lifecycle

    init() {
        values = Dictionary(uniqueKeysWithValues: Self.keys.map { ($0, UserDefaults.standard.object(forKey: $0)) })
        appearanceMode = ThemeService.shared.appearanceMode
        themeStyle = ThemeService.shared.themeStyle
    }

    // MARK: Internal

    func restore() {
        ThemeService.shared.appearanceMode = appearanceMode
        ThemeService.shared.themeStyle = themeStyle

        let defaults = UserDefaults.standard
        for (key, value) in values {
            if let value {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    // MARK: Private

    // Private to their modules, so repeated here.
    private static let keys = [
        // AudioPreferences.swift
        "audioEndKey",
        "audioPlaybackRate",
        "audioStreamingEnabled",
        "audioVerseDelay",
        "audioRepetitionDelay",
        "audioVerseRuns",
        "audioListRuns",
        // ReciterPreferences.swift
        "LastSelectedQariId",
        // ReadingPreferences.swift
        "quranReading",
        // QuranContentStatePreferences.swift
        "showQuranTranslationView",
        "twoPagesEnabled",
        "showArabicInTranslation",
        "ayahIndicators",
        // SelectedTranslationsPreferences.swift
        "selectedTranslations",
        // FontSizePreferences.swift
        "translationFontSize",
        "arabicFont",
        // ThemeService.swift
        "theme",
        "themeStyle",
        // WordTextPreferences.swift
        "wordTranslationType",
        "isWordPointerActive",
    ]

    private let values: [String: Any?]
    private let appearanceMode: AppearanceMode
    private let themeStyle: ThemeStyle
}
