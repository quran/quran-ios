//
//  QuranArabicText.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import Localization
import QuranKit
import QuranText
import SwiftUI

public struct QuranArabicText: View {
    @ScaledMetric var bottomPadding = 5
    @ScaledMetric var topPadding = 10

    let verse: AyahNumber
    let text: String
    let fontSize: FontSize

    public init(verse: AyahNumber, text: String, fontSize: FontSize) {
        self.verse = verse
        self.text = text
        self.fontSize = fontSize
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lFormat("translation.text.ayah-number", verse.sura.suraNumber, verse.ayah))
                .padding(8)
                .foregroundColor(.secondaryLabel)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.systemGray5.opacity(0.5))
                )

            Text(text)
                .font(.quran())
                .dynamicTypeSize(fontSize.dynamicTypeSize)
                .textAlignment(follows: .rightToLeft)
        }
        .padding(.bottom, bottomPadding)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }
}
