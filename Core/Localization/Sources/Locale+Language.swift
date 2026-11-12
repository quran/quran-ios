//
//  Locale+Language.swift
//

import Foundation

public extension Locale {
    /// The locale of the language the app's strings resolved to.
    ///
    /// This follows the localization `l()` reads, which differs from the first preferred language when
    /// the app lacks it (a phone set to Urdu then Arabic shows Arabic strings). In the app this is
    /// normally `Locale.current`, because the app and this module ship the same localizations, so numbers
    /// follow the user's region and number format, as they do in `lFormat` and SwiftUI.
    ///
    /// A host whose main bundle has other localizations (such as the Example app, which has only `en`)
    /// can have a `Locale.current` in another language. Then this is the first preferred language in the
    /// resolved language, such as `ar-SA`, so the region still decides the digits.
    static var preferredLanguageLocale: Locale {
        preferredLanguageLocale(localization: moduleLocalization, preferredLanguages: Locale.preferredLanguages, current: .current)
    }

    var isArabicLanguage: Bool {
        languageCode == "ar"
    }

    /// Whether the locale's language writes right to left, such as Arabic, Persian, or Uyghur.
    var isRightToLeft: Bool {
        Locale.characterDirection(forLanguage: languageCode ?? "") == .rightToLeft
    }
}

extension Locale {
    // MARK: Internal

    /// - Parameters:
    ///   - localization: The localization the strings resolved to, such as `ar`.
    ///   - preferredLanguages: The app's preferred languages, such as `["ur-PK", "ar-PK"]`.
    ///   - current: The current locale.
    static func preferredLanguageLocale(localization: String?, preferredLanguages: [String], current: Locale) -> Locale {
        guard let localization else {
            return current
        }
        let languageCode = Locale(identifier: localization).languageCode
        if languageCode == current.languageCode {
            return current
        }
        let preferredLanguage = preferredLanguages.first { Locale(identifier: $0).languageCode == languageCode }
        return Locale(identifier: preferredLanguage ?? localization)
    }

    // MARK: Private

    /// Read once: changing the app's language relaunches it.
    private static let moduleLocalization = Bundle.fixedModule.preferredLocalizations.first
}
