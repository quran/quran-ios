//
//  TranslatedPage.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-02-20.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Foundation
import QuranKit
import QuranText

struct TranslatedPage: Equatable {
    let translatedVerses: [TranslatedVerse]
}

struct TranslatedVerse: Equatable {
    let verse: AyahNumber
    let text: VerseText
    let translations: Translations
}

class Translations: Equatable, CustomStringConvertible {
    // MARK: Lifecycle

    init(_ translations: [Translation]) {
        self.translations = translations
    }

    // MARK: Internal

    let translations: [Translation]

    var description: String {
        "Translations: \(translations)"
    }

    static func == (lhs: Translations, rhs: Translations) -> Bool {
        lhs.translations == rhs.translations
    }
}
