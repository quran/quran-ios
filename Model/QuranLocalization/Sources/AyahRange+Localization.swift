//
//  AyahRange+Localization.swift
//

import Foundation
import Localization
import QuranKit

/// One compact format for ayah ranges: "Al-Baqarah 2:1–10" in one sura, "Al-Baqarah 2:286 – Āli-ʿImrān 3:10"
/// across suras, "Al-Baqarah 2:255" for one ayah, and "Al-Baqarah" for a whole sura.
extension ClosedRange<AyahNumber> {
    // MARK: Public

    /// The sura when the range covers all of it, from its first ayah through its last.
    public var wholeSura: Sura? {
        let sura = lowerBound.sura
        return lowerBound == sura.firstVerse && upperBound == sura.lastVerse ? sura : nil
    }

    /// The coordinates of ayahs in one sura as one left-to-right run with the app's digits, such as "2:1–10", or
    /// "2:255" for one ayah. Right-to-left languages isolate the run, so it never reads as "10–2:1".
    public func localizedCoordinates(locale: Locale = .preferredLanguageLocale) -> String {
        var coordinates = lowerBound.localizedCoordinate(locale: locale)
        if lowerBound != upperBound {
            coordinates += "–\(locale.formatNumber(upperBound.ayah))"
        }
        return locale.isRightToLeft ? "\u{2066}\(coordinates)\u{2069}" : coordinates
    }

    /// The range as plain text, such as "Al-Baqarah 2:1–10" or "Al-Baqarah 2:286 – Āli-ʿImrān 3:10".
    public func localizedName(language: Language? = nil, locale: Locale = .preferredLanguageLocale) -> String {
        if let wholeSura {
            return wholeSura.localizedName(language: language)
        }
        func reference(_ range: Self) -> String {
            "\(range.lowerBound.sura.localizedName(language: language)) \(range.localizedCoordinates(locale: locale))"
        }
        guard lowerBound.sura != upperBound.sura else {
            return reference(self)
        }
        return lFormat("quran.range", language: language, reference(lowerBound ... lowerBound), reference(upperBound ... upperBound))
    }

    /// The range as VoiceOver reads it, such as "Al-Baqarah, Ayahs 1 to 10" or
    /// "Al-Baqarah, Ayah 286 to Āli-ʿImrān, Ayah 10".
    public func localizedAccessibilityName(language: Language? = nil, locale: Locale = .preferredLanguageLocale) -> String {
        if let wholeSura {
            return wholeSura.localizedName(language: language)
        }
        if lowerBound == upperBound {
            return lowerBound.localizedName(language: language)
        }
        guard lowerBound.sura == upperBound.sura else {
            return lFormat(
                "quran.range.spoken",
                language: language,
                lowerBound.localizedName(language: language),
                upperBound.localizedName(language: language)
            )
        }
        let ayahs = lFormat(
            "quran.ayah.number-range",
            language: language,
            locale.formatNumber(lowerBound.ayah),
            locale.formatNumber(upperBound.ayah)
        )
        return lFormat("quran.ayah.name", language: language, lowerBound.sura.localizedName(language: language), ayahs)
    }
}

extension Locale {
    /// The number with the app's digits for this locale.
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = fixedLocaleNumbers()
        return formatter.format(number)
    }
}
