//
//  TranslatedVerses.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/23/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import QuranKit

public struct TranslationString: Hashable {
    // MARK: Lifecycle

    public init(text: String, quranRanges: [Range<String.Index>], footnoteRanges: [Range<String.Index>], footnotes: [Substring]) {
        self.text = text
        self.quranRanges = quranRanges
        self.footnoteRanges = footnoteRanges
        self.footnotes = footnotes
    }

    // MARK: Public

    public let text: String
    public let quranRanges: [Range<String.Index>]
    public let footnoteRanges: [Range<String.Index>]
    public let footnotes: [Substring]
}

public enum TranslationText: Hashable {
    case string(TranslationString)
    case reference(AyahNumber)
}

public struct VerseText: Equatable {
    // MARK: Lifecycle

    public init(arabicText: String, translations: [TranslationText], arabicPrefix: [String], arabicSuffix: [String]) {
        self.arabicText = arabicText
        self.translations = translations
        self.arabicPrefix = arabicPrefix
        self.arabicSuffix = arabicSuffix
    }

    // MARK: Public

    public let arabicText: String
    public let translations: [TranslationText] // count equals to TranslatedVerses.translations.count
    public let arabicPrefix: [String]
    public let arabicSuffix: [String]
}

public struct TranslatedVerses: Equatable {
    // MARK: Lifecycle

    public init(translations: [Translation], verses: [VerseText]) {
        self.translations = translations
        self.verses = verses
    }

    // MARK: Public

    public let translations: [Translation]
    public let verses: [VerseText]
}
