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
import TranslationService

public struct TranslationString: Equatable {
    public init(text: String, quranRanges: [NSRange], footerRanges: [NSRange]) {
        self.text = text
        self.footerRanges = footerRanges
        self.quranRanges = quranRanges
    }

    public let text: String
    public let quranRanges: [NSRange]
    public let footerRanges: [NSRange]
}

public enum TranslationText: Equatable {
    case string(TranslationString)
    case reference(AyahNumber)
}

public struct VerseText: Equatable {
    public let arabicText: String
    public let translations: [TranslationText] // count equals to TranslatedVerses.translations.count
    public let arabicPrefix: [String]
    public let arabicSuffix: [String]
}

public struct TranslatedVerses: Equatable {
    public let translations: [Translation]
    public let verses: [VerseText]
}
