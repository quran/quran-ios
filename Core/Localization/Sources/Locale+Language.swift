//
//  Locale+Language.swift
//

import Foundation

public extension Locale {
    static var preferredLanguageLocale: Locale {
        guard let identifier = NSLocale.preferredLanguages.first else {
            return .current
        }
        return Locale(identifier: identifier)
    }

    var isArabicLanguage: Bool {
        languageCode == "ar"
    }
}
