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
    /// A range of the footnote's text to link, such as a verse reference, with its URL.
    public typealias Link = (range: Range<String.Index>, url: URL)

    @ScaledMetric private var topPadding = 5

    let text: String
    let chunk: Range<String.Index>
    let marker: String?
    let links: [Link]
    let font: Font
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection

    public init(text: String, chunk: Range<String.Index>, marker: String?, links: [Link] = [], font: Font, fontSize: FontSize, characterDirection: Locale.LanguageDirection) {
        self.text = text
        self.chunk = chunk
        self.marker = marker
        self.links = links
        self.font = font
        self.fontSize = fontSize
        self.characterDirection = characterDirection
    }

    public var body: some View {
        Text(string)
            .themedSecondaryForeground()
            .font(font)
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: characterDirection)
            .padding(.top, marker == nil ? 0 : topPadding)
            .readableInsetsPadding(.horizontal)
    }

    private var string: AttributedString {
        var string = AttributedString(text[chunk])
        for link in links {
            if let range = string.range(from: link.range, overallRange: chunk, overallText: text) {
                string[range].link = link.url
            }
        }

        guard let marker else {
            return string
        }
        var markedString = AttributedString("\(marker) ")
        markedString.append(string)
        return markedString
    }
}

private func previewChunk(_ text: String, marker: String?, linking linkedText: String? = nil, font: Font = .footnote, characterDirection: Locale.LanguageDirection = .leftToRight) -> QuranTranslationFootnoteChunk {
    QuranTranslationFootnoteChunk(
        text: text,
        chunk: text.startIndex ..< text.endIndex,
        marker: marker,
        links: linkedText.flatMap { text.range(of: $0) }.map { [($0, URL(validURL: "https://quran.com"))] } ?? [],
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
        previewChunk("See footnote for {6:38}.", marker: "[3]", linking: "{6:38}")
        previewChunk("أي: ثبّتنا على الصراط المستقيم.", marker: "[1]", font: .arabicTafseerFootnote(), characterDirection: .rightToLeft)
    }
    .padding()
    .themedBackground()
}
