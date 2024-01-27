//
//  TranslationItem.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import QuranKit
import QuranText
import SwiftUI

enum TranslationItemId: Hashable, Sendable {
    case pageHeader(Page)
    case pageFooter(Page)
    case separator(AyahNumber)
    case suraName(Sura)
    case arabic(AyahNumber)
    case translator(AyahNumber, translationId: Translation.ID)
    case translationReference(AyahNumber, translationId: Translation.ID)
    case translationTextChunk(AyahNumber, translationId: Translation.ID, chunkIndex: Int)

    var ayah: AyahNumber? {
        switch self {
        case .pageHeader, .pageFooter:
            nil
        case .suraName(let sura):
            sura.firstVerse
        case .separator(let ayahNumber),
             .arabic(let ayahNumber),
             .translator(let ayahNumber, _),
             .translationReference(let ayahNumber, _),
             .translationTextChunk(let ayahNumber, _, _):
            ayahNumber
        }
    }
}

struct TranslationPageHeader: Identifiable & Hashable {
    let page: Page

    var id: TranslationItemId { .pageHeader(page) }
}

struct TranslationPageFooter: Identifiable & Hashable {
    let page: Page

    var id: TranslationItemId { .pageFooter(page) }
}

struct TranslationVerseSeparator: Identifiable & Hashable {
    let verse: AyahNumber

    var id: TranslationItemId { .separator(verse) }
}

struct TranslationSuraName: Identifiable & Hashable {
    let sura: Sura
    let arabicFontSize: FontSize

    var id: TranslationItemId { .suraName(sura) }
}

struct TranslationArabicText: Identifiable & Hashable {
    let verse: AyahNumber
    let text: String
    let arabicFontSize: FontSize

    var id: TranslationItemId { .arabic(verse) }
}

struct TranslationTextChunk: Identifiable & Hashable {
    let verse: AyahNumber
    let translation: Translation
    let text: TranslationString
    let chunks: [Range<String.Index>]
    let chunkIndex: Int
    let readMore: Bool

    let translationFontSize: FontSize

    var id: TranslationItemId { .translationTextChunk(verse, translationId: translation.id, chunkIndex: chunkIndex) }
}

struct TranslationReferenceVerse: Identifiable & Hashable {
    let verse: AyahNumber

    let translation: Translation
    let reference: AyahNumber

    let translationFontSize: FontSize

    var id: TranslationItemId { .translationReference(verse, translationId: translation.id) }
}

struct TranslatorText: Identifiable & Hashable {
    let verse: AyahNumber
    let translation: Translation

    let translationFontSize: FontSize

    var id: TranslationItemId { .translator(verse, translationId: translation.id) }
}

enum TranslationItem: Identifiable & Hashable {
    case pageHeader(TranslationPageHeader)
    case pageFooter(TranslationPageFooter)
    case verseSeparator(TranslationVerseSeparator, Color?)
    case suraName(TranslationSuraName, Color?)
    case arabicText(TranslationArabicText, Color?)
    case translationTextChunk(TranslationTextChunk, Color?)
    case translationReferenceVerse(TranslationReferenceVerse, Color?)
    case translatorText(TranslatorText, Color?)

    var id: TranslationItemId {
        switch self {
        case .pageHeader(let item): return item.id
        case .pageFooter(let item): return item.id
        case .verseSeparator(let item, _): return item.id
        case .suraName(let item, _): return item.id
        case .arabicText(let item, _): return item.id
        case .translationTextChunk(let item, _): return item.id
        case .translationReferenceVerse(let item, _): return item.id
        case .translatorText(let item, _): return item.id
        }
    }

    var color: Color? {
        switch self {
        case .pageHeader, .pageFooter:
            return nil
        case .verseSeparator(_, let color),
             .suraName(_, let color),
             .arabicText(_, let color),
             .translationTextChunk(_, let color),
             .translationReferenceVerse(_, let color),
             .translatorText(_, let color):
            return color
        }
    }
}
