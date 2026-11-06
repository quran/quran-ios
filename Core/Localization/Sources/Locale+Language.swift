//
//  Locale+Language.swift
//

import Foundation

public extension Locale {
    /// The locale of the app's preferred language.
    ///
    /// This is `Locale.current` when it uses that language, so numbers follow the user's region and
    /// number format, as they do in `lFormat` and SwiftUI.
    static var preferredLanguageLocale: Locale {
        preferredLanguageLocale(preferredLanguages: NSLocale.preferredLanguages, current: .current)
    }

    var isArabicLanguage: Bool {
        languageCode == "ar"
    }
}

extension Locale {
    static func preferredLanguageLocale(preferredLanguages: [String], current: Locale) -> Locale {
        guard let identifier = preferredLanguages.first else {
            return current
        }
        let locale = Locale(identifier: identifier)
        return locale.languageCode == current.languageCode ? current : locale
    }
}
