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

public struct QuranArabicText: View {
    @ScaledMetric var bottomPadding = 5
    @ScaledMetric var topPadding = 10
    @ScaledMetric var cornerRadius = 6

    let verse: AyahNumber
    let text: QuranText
    let fontSize: FontSize

    public init(verse: AyahNumber, text: QuranText, fontSize: FontSize) {
        self.verse = verse
        self.text = text
        self.fontSize = fontSize
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lFormat("translation.text.ayah-number", verse.sura.suraNumber, verse.ayah))
                .padding(8)
                .themedSecondaryForeground()
                .themedSecondaryBackground()
                .cornerRadius(cornerRadius)

            QuranTextView(
                text,
                fontName: verse.quran.translationQuranFontName,
                fontOverrides: ayahMarkerFontOverrides
            )
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: .rightToLeft)
        }
        .padding(.bottom, bottomPadding)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }

    var ayahMarkerFontOverrides: [QuranTextFontOverride] {
        guard verse.quran == .hafsIndoPak else {
            return []
        }
        let marker = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        guard let range = text.text.range(of: marker, options: .backwards),
              range.upperBound == text.text.endIndex
        else {
            return []
        }
        return [QuranTextFontOverride(range: range, fontName: .uthmanicHafs)]
    }
}
