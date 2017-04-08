//
//  TranslationPageLayout.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
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

import UIKit

struct LongTranslationTextLayout {
    let textContainer: NSTextContainer
    let numberOfGlyphs: Int
}

struct TranslationTextLayout: Hashable {
    let text: TranslationText
    let size: CGSize
    let longTextLayout: LongTranslationTextLayout?
    let translatorSize: CGSize

    var hashValue: Int {
        return text.text.hashValue ^ size.width.hashValue ^ text.translation.id.hashValue
    }

    static func == (lhs: TranslationTextLayout, rhs: TranslationTextLayout) -> Bool {
        return
            lhs.text.translation.id == rhs.text.translation.id &&
            lhs.size.width          == rhs.size.width &&
            lhs.text.text           == rhs.text.text
    }
}

struct TranslationArabicTextLayout {
    let arabicText: String
    let size: CGSize
}

struct TranslationVerseLayout {
    let ayah: AyahNumber
    let arabicTextLayout: TranslationArabicTextLayout
    let translationLayouts: [TranslationTextLayout]

    let arabicPrefixLayouts: [TranslationArabicTextLayout]
    let arabicSuffixLayouts: [TranslationArabicTextLayout]
}

struct TranslationPageLayout {
    let pageNumber: Int
    let verseLayouts: [TranslationVerseLayout]
}
