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
    case arabic(AyahNumber)
    case verseNumber(AyahNumber)
    case translator(AyahNumber, translationId: Translation.ID)
    case translationReference(AyahNumber, translationId: Translation.ID)
    case translationTextChunk(AyahNumber, translationId: Translation.ID, chunkIndex: Int)
    case translationFootnoteChunk(AyahNumber, translationId: Translation.ID, footnoteIndex: Int, chunkIndex: Int)

    var ayah: AyahNumber? {
        switch self {
        case .pageHeader, .pageFooter:
            nil
        case .suraName(let sura):
            sura.firstVerse
        case .separator(let ayahNumber),
             .arabic(let ayahNumber),
             .verseNumber(let ayahNumber),
             .translator(let ayahNumber, _),
             .translationReference(let ayahNumber, _),
             .translationTextChunk(let ayahNumber, _, _),
             .translationFootnoteChunk(let ayahNumber, _, _, _):
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

struct TranslationArabicText: Identifiable & Hashable {
    let verse: AyahNumber
    let text: QuranText
    let quranFont: QuranFont
    let arabicFontSize: FontSize

    var id: TranslationItemId { .arabic(verse) }
}

struct TranslationVerseNumber: Identifiable & Hashable {
    let verse: AyahNumber

    #if QURAN_SYNC
    let indicators: Set<AyahIndicator>
    #endif

    var id: TranslationItemId { .verseNumber(verse) }
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

struct TranslationFootnoteChunk: Identifiable & Hashable {
    let verse: AyahNumber
    let translation: Translation
    let footnoteIndex: Int
    /// The footnote's marker, such as "[1]"; first chunk only.
    let marker: String?
    let text: String
    /// The verse references in `text` that the reader can follow.
    let verseReferences: [FootnoteVerseReference]
    let chunks: [Range<String.Index>]
    let chunkIndex: Int

    let translationFontSize: FontSize

    var id: TranslationItemId {
        .translationFootnoteChunk(verse, translationId: translation.id, footnoteIndex: footnoteIndex, chunkIndex: chunkIndex)
    }
}

extension TranslationString {
    /// The footnote without its surrounding brackets and whitespace.
    func footnoteText(at index: Int) -> String {
        footnotes[index].trimmingCharacters(in: Self.footnoteTrimmedCharacters)
    }

    private static let footnoteTrimmedCharacters = CharacterSet(charactersIn: "[]").union(.whitespacesAndNewlines)
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

/// A verse row's highlight and dimming.
struct TranslationVerseDecoration: Hashable {
    var color: Color?
    var isDimmed = false
}

enum TranslationItem: Identifiable & Hashable {
    case pageHeader(TranslationPageHeader)
    case pageFooter(TranslationPageFooter)
    case verseSeparator(TranslationVerseSeparator, TranslationVerseDecoration)
    case suraName(TranslationSuraName, TranslationVerseDecoration)
    case arabicText(TranslationArabicText, TranslationVerseDecoration)
    case verseNumber(TranslationVerseNumber, TranslationVerseDecoration)
    case translationTextChunk(TranslationTextChunk, TranslationVerseDecoration)
    case translationFootnoteChunk(TranslationFootnoteChunk, TranslationVerseDecoration)
    case translationReferenceVerse(TranslationReferenceVerse, TranslationVerseDecoration)
    case translatorText(TranslatorText, TranslationVerseDecoration)

    var id: TranslationItemId {
        switch self {
        case .pageHeader(let item): return item.id
        case .pageFooter(let item): return item.id
        case .verseSeparator(let item, _): return item.id
        case .suraName(let item, _): return item.id
        case .arabicText(let item, _): return item.id
        case .verseNumber(let item, _): return item.id
        case .translationTextChunk(let item, _): return item.id
        case .translationFootnoteChunk(let item, _): return item.id
        case .translationReferenceVerse(let item, _): return item.id
        case .translatorText(let item, _): return item.id
        }
    }

    var decoration: TranslationVerseDecoration {
        switch self {
        case .pageHeader, .pageFooter:
            return TranslationVerseDecoration()
        case .verseSeparator(_, let decoration),
             .suraName(_, let decoration),
             .arabicText(_, let decoration),
             .verseNumber(_, let decoration),
             .translationTextChunk(_, let decoration),
             .translationFootnoteChunk(_, let decoration),
             .translationReferenceVerse(_, let decoration),
             .translatorText(_, let decoration):
            return decoration
        }
    }
}
