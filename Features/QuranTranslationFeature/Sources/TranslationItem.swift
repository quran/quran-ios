//
//  TranslationItem.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import NoorUI
import QuranAnnotations
import QuranKit
import QuranText
import SwiftUI

enum TranslationItemId: Hashable, Sendable {
    case pageHeader(Page)
    case pageFooter(Page)
    case separator(AyahNumber)
    case suraName(Sura)
    case verseNumber(AyahNumber)
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
             .verseNumber(let ayahNumber),
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
    let showsBesmAllah: Bool
    let quranFont: QuranFont
    let arabicFontSize: FontSize

    var id: TranslationItemId { .suraName(sura) }
}

struct TranslationArabicText: Hashable {
    let verse: AyahNumber
    let text: QuranText
    let quranFont: QuranFont
    let arabicFontSize: FontSize
}

/// The verse-number capsule. It starts each verse: in the verse header, or in the first
/// translation row when the Arabic text is hidden.
struct TranslationVerseNumber: Hashable {
    let verse: AyahNumber

    #if QURAN_SYNC
    let annotations: Set<AyahAnnotation>
    #endif
}

/// A verse's anchor row when the Arabic text is shown: its verse number and Arabic text.
struct TranslationVerseHeader: Identifiable & Hashable {
    let verseNumber: TranslationVerseNumber
    let arabicText: TranslationArabicText

    var verse: AyahNumber { verseNumber.verse }

    var id: TranslationItemId { .verseNumber(verse) }
}

struct TranslationTextChunk: Identifiable & Hashable {
    let verse: AyahNumber
    let translation: Translation
    let text: TranslationString
    let chunks: [Range<String.Index>]
    let chunkIndex: Int
    let readMore: Bool
    let verseNumber: TranslationVerseNumber?

    let translationFontSize: FontSize

    var id: TranslationItemId { .translationTextChunk(verse, translationId: translation.id, chunkIndex: chunkIndex) }
}

struct TranslationReferenceVerse: Identifiable & Hashable {
    let verse: AyahNumber

    let translation: Translation
    let reference: AyahNumber
    let verseNumber: TranslationVerseNumber?

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
    case verseHeader(TranslationVerseHeader, Color?)
    case translationTextChunk(TranslationTextChunk, Color?)
    case translationReferenceVerse(TranslationReferenceVerse, Color?)
    case translatorText(TranslatorText, Color?)

    var id: TranslationItemId {
        switch self {
        case .pageHeader(let item): return item.id
        case .pageFooter(let item): return item.id
        case .verseSeparator(let item, _): return item.id
        case .suraName(let item, _): return item.id
        case .verseHeader(let item, _): return item.id
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
             .verseHeader(_, let color),
             .translationTextChunk(_, let color),
             .translationReferenceVerse(_, let color),
             .translatorText(_, let color):
            return color
        }
    }
}
