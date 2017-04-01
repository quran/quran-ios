//
//  TranslationPageLayout.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
}

struct TranslationPageLayout {
    let pageNumber: Int
    let arabicPrefixLayouts: [TranslationArabicTextLayout]
    let verseLayouts: [TranslationVerseLayout]
    let arabicSuffixLayouts: [TranslationArabicTextLayout]
}
