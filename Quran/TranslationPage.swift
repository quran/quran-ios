//
//  TranslationPage.swift
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

struct TranslationText {
    let translation: Translation
    let text: String
    let isLongText: Bool
}

struct TranslationVerse {
    let ayah: AyahNumber
    let arabicText: String
    let translations: [TranslationText]
    let arabicPrefix: [String]
    let arabicSuffix: [String]
}

struct TranslationPage: Hashable {
    let pageNumber: Int
    let verses: [TranslationVerse]

    private var translationIds: [Int] {
        return verses.first?.translations.map { $0.translation.id } ?? []
    }

    var hashValue: Int {
        return pageNumber.hashValue ^ translationIds.map { "\($0)" }.joined().hashValue
    }

    static func == (lhs: TranslationPage, rhs: TranslationPage) -> Bool {
        guard lhs.hashValue == rhs.hashValue else { return false }
        return lhs.pageNumber == rhs.pageNumber && lhs.translationIds == rhs.translationIds
    }
}
