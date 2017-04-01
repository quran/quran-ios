//
//  TranslationPage.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
}

struct TranslationPage: Hashable {
    let pageNumber: Int
    let arabicPrefix: [String]
    let verses: [TranslationVerse]
    let arabicSuffix: [String]

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
