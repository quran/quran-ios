//
//  QuranTranslationFootnoteChunk.swift
//
//
//  Created by Marouane on 2026-11-03.
//

import QuranText
import SwiftUI
import UIx

/// A chunk of a translation footnote; only the first chunk shows its marker.
public struct QuranTranslationFootnoteChunk: View {
    @ScaledMetric private var topPadding = 5

    let text: String
    let chunk: Range<String.Index>
    let marker: String?
    let font: Font
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection

    public init(text: String, chunk: Range<String.Index>, marker: String?, font: Font, fontSize: FontSize, characterDirection: Locale.LanguageDirection) {
        self.text = text
        self.chunk = chunk
        self.marker = marker
        self.font = font
        self.fontSize = fontSize
        self.characterDirection = characterDirection
    }

    public var body: some View {
        Text(verbatim: marker.map { "\($0) \(text[chunk])" } ?? String(text[chunk]))
            .themedSecondaryForeground()
            .font(font)
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: characterDirection)
            .padding(.top, marker == nil ? 0 : topPadding)
            .readableInsetsPadding(.horizontal)
    }
}

private func previewChunk(_ text: String, marker: String?, font: Font = .footnote, characterDirection: Locale.LanguageDirection = .leftToRight) -> QuranTranslationFootnoteChunk {
    QuranTranslationFootnoteChunk(
        text: text,
        chunk: text.startIndex ..< text.endIndex,
        marker: marker,
        font: font,
        fontSize: .medium,
        characterDirection: characterDirection
    )
}

#Preview {
    VStack(spacing: 0) {
        previewChunk("The unseen includes Allah, the angels, the Day of Judgment, Paradise and Hell.", marker: "[1]")
        previewChunk("It continues in a second chunk without a marker.", marker: nil)
        previewChunk("Lit., what We have provided for them.", marker: "[2]")
        previewChunk("أي: ثبّتنا على الصراط المستقيم.", marker: "[1]", font: .arabicTafseerFootnote(), characterDirection: .rightToLeft)
    }
    .padding()
    .themedBackground()
}
