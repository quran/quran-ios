//
//  QuranArabicText.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import Localization
import NoorFont
import QuranAnnotations
import QuranKit
import QuranText
import SwiftUI
import UIx

public struct QuranArabicText: View {
    @ScaledMetric var bottomPadding = 5
    @ScaledMetric var topPadding = 10

    let verse: AyahNumber
    let text: QuranText
    let quranFont: QuranFont
    let fontSize: FontSize

    #if QURAN_SYNC
    private let annotations: Set<AyahAnnotation>
    private let onAyahNumberTapped: (CGPoint) -> Void

    public init(verse: AyahNumber, text: QuranText, quranFont: QuranFont, fontSize: FontSize, annotations: Set<AyahAnnotation>, onAyahNumberTapped: @escaping (CGPoint) -> Void) {
        self.verse = verse
        self.text = text
        self.quranFont = quranFont
        self.fontSize = fontSize
        self.annotations = annotations
        self.onAyahNumberTapped = onAyahNumberTapped
    }
    #else
    public init(verse: AyahNumber, text: QuranText, quranFont: QuranFont, fontSize: FontSize) {
        self.verse = verse
        self.text = text
        self.quranFont = quranFont
        self.fontSize = fontSize
    }
    #endif

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ayahNumber

            QuranTextView(
                text,
                quranFont: quranFont,
                fontOverrides: ayahMarkerFontOverrides
            )
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: .rightToLeft)
        }
        .padding(.bottom, bottomPadding)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }

    @ViewBuilder
    private var ayahNumber: some View {
        #if QURAN_SYNC
        QuranVerseNumber(verse: verse, annotations: annotations, onTapped: onAyahNumberTapped)
        #else
        QuranVerseNumber(verse: verse)
        #endif
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
