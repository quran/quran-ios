//
//  AnalyticsUserPropertyValue+Settings.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import NoorUI
import QueuePlayer
import QuranAudio
import QuranKit
import QuranText

// Explicit names, so renumbered raw values or edited descriptions never change a reported value.
extension AnalyticsUserPropertyValue {
    // MARK: Audio

    static func playbackRate(_ rate: Float) -> String {
        decimal(Double(rate))
    }

    static func audioEnd(_ audioEnd: AudioEnd) -> String {
        switch audioEnd {
        case .page: "page"
        case .quarter: "quarter"
        case .hizb: "hizb"
        case .juz: "juz"
        case .sura: "sura"
        case .quran: "quran"
        }
    }

    static func runs(_ runs: Runs) -> String {
        switch runs {
        case .finite(let count): String(count)
        case .indefinite: "inf"
        }
    }

    static func verseDelay(_ delay: VerseDelay) -> String {
        decimal(delay.multiplier)
    }

    static func repetitionDelay(_ delay: RepetitionDelay) -> String {
        decimal(delay.seconds)
    }

    static func reciter(nameKey: String) -> String {
        let prefix = "qari_"
        let name = nameKey.hasPrefix(prefix) ? String(nameKey.dropFirst(prefix.count)) : nameKey
        return limited(name)
    }

    // MARK: Reading

    static func mushaf(_ reading: Reading) -> String {
        switch reading {
        case .hafs_1405: "hafs_1405"
        case .hafs_1440: "hafs_1440"
        case .tajweed: "tajweed"
        case .hafs_1421: "hafs_1421"
        case .hafs_1441: "hafs_1441"
        case .hafs_1439: "hafs_1439"
        case .indoPak: "indopak"
        }
    }

    static func quranMode(_ mode: QuranMode) -> String {
        switch mode {
        case .arabic: "arabic"
        case .translation: "translation"
        }
    }

    static func fontSize(_ size: FontSize) -> String {
        switch size {
        case .accessibility5: "accessibility5"
        case .accessibility4: "accessibility4"
        case .accessibility3: "accessibility3"
        case .accessibility2: "accessibility2"
        case .accessibility1: "accessibility1"
        case .xxxLarge: "xxxLarge"
        case .xxLarge: "xxLarge"
        case .xLarge: "xLarge"
        case .large: "large"
        case .medium: "medium"
        case .small: "small"
        case .xSmall: "xSmall"
        }
    }

    static func appearance(_ mode: AppearanceMode) -> String {
        switch mode {
        case .light: "light"
        case .dark: "dark"
        case .auto: "auto"
        }
    }

    static func themeStyle(_ style: ThemeStyle) -> String {
        switch style {
        case .calm: "calm"
        case .focus: "focus"
        case .original: "original"
        case .paper: "paper"
        case .quiet: "quiet"
        }
    }

    static func wordPointer(isActive: Bool, textType: WordTextType) -> String {
        guard isActive else {
            return "off"
        }
        switch textType {
        case .translation: return "translation"
        case .transliteration: return "transliteration"
        }
    }

    #if QURAN_SYNC
    static func ayahIndicators(_ visibility: AyahIndicatorVisibility) -> String {
        switch visibility {
        case .all: "all"
        case .readingBookmark: "reading_bookmark"
        case .none: "none"
        }
    }
    #endif
}
