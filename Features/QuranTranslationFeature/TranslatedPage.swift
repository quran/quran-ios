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

public struct TranslatedVerse: Equatable {
    // MARK: Lifecycle

    public init(verse: AyahNumber, text: VerseText, translations: Translations) {
        self.verse = verse
        self.text = text
        self.translations = translations
    }

    // MARK: Public

    public let verse: AyahNumber

    // MARK: Internal

    let text: VerseText
    let translations: Translations
}

// TODO: Remove
public class Translations: Equatable, CustomStringConvertible {
    // MARK: Lifecycle

    public init(_ translations: [Translation]) {
        self.translations = translations
    }

    // MARK: Public

    public var description: String {
        "Translations: \(translations)"
    }

    public static func == (lhs: Translations, rhs: Translations) -> Bool {
        lhs.translations == rhs.translations
    }

    // MARK: Internal

    let translations: [Translation]
}
