//
//  QuranArabicText.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import Localization
import NoorFont
import QuranKit
import QuranText
import SwiftUI

/// A verse's Quran text in translation mode, without layout. `QuranVerseHeader` places it.
public struct QuranArabicText: View {
    let verse: AyahNumber
    let text: QuranText
    let quranFont: QuranFont
    let fontSize: FontSize

    public init(verse: AyahNumber, text: QuranText, quranFont: QuranFont, fontSize: FontSize) {
        self.verse = verse
        self.text = text
        self.quranFont = quranFont
        self.fontSize = fontSize
    }

    public var body: some View {
        QuranTextView(
            text,
            quranFont: quranFont,
            fontOverrides: ayahMarkerFontOverrides
        )
        .dynamicTypeSize(fontSize.dynamicTypeSize)
    }

    var ayahMarkerFontOverrides: [QuranTextFontOverride] {
        guard quranFont == .indoPak else {
            return []
        }
        let marker = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        guard let range = text.text.range(of: marker, options: .backwards),
              range.upperBound == text.text.endIndex
        else {
            return []
        }
        return [QuranTextFontOverride(range: range, quranFont: .uthmanicHafs)]
    }
}
