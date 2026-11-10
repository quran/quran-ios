//
//  QuranTranslationFootnote.swift
//
//
//  Created by Marouane on 2026-11-03.
//

import QuranText
import SwiftUI
import UIx

/// A translator's footnote under the translation text, introduced by the marker that refers to it there.
public struct QuranTranslationFootnote: View {
    @ScaledMetric private var topPadding = 5

    let marker: String
    let text: String
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection

    public init(marker: String, text: String, fontSize: FontSize, characterDirection: Locale.LanguageDirection) {
        self.marker = marker
        self.text = text
        self.fontSize = fontSize
        self.characterDirection = characterDirection
    }

    public var body: some View {
        Text(verbatim: "\(marker) \(text)")
            .themedSecondaryForeground()
            .font(.footnote)
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: characterDirection)
            .padding(.top, topPadding)
            .readableInsetsPadding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 0) {
        QuranTranslationFootnote(
            marker: "[1]",
            text: "The unseen includes Allah, the angels, the Day of Judgment, Paradise and Hell.",
            fontSize: .medium,
            characterDirection: .leftToRight
        )
        QuranTranslationFootnote(
            marker: "[2]",
            text: "Lit., what We have provided for them.",
            fontSize: .medium,
            characterDirection: .leftToRight
        )
        QuranTranslationFootnote(
            marker: "[1]",
            text: "أي: ثبّتنا على الصراط المستقيم.",
            fontSize: .medium,
            characterDirection: .rightToLeft
        )
    }
    .padding()
    .themedBackground()
}
