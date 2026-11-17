//
//  QuranTranslationTextChunk.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import Localization
import QuranText
import SwiftUI
import UIx

public struct QuranTranslationTextChunk: View {
    @ScaledMetric var topPadding = 10
    @ScaledMetric var baselineOffset = 5

    let text: String
    let chunk: Range<String.Index>
    let footnoteRanges: [Range<String.Index>]
    let quranRanges: [Range<String.Index>]

    let firstChunk: Bool
    let readMoreURL: URL?
    let footnoteURL: (Int) -> URL

    let font: Font
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection

    public init(text: String, chunk: Range<String.Index>, footnoteRanges: [Range<String.Index>], quranRanges: [Range<String.Index>], firstChunk: Bool, readMoreURL: URL?, footnoteURL: @escaping (Int) -> URL, font: Font, fontSize: FontSize, characterDirection: Locale.LanguageDirection) {
        self.text = text
        self.chunk = chunk
        self.footnoteRanges = footnoteRanges
        self.quranRanges = quranRanges
        self.firstChunk = firstChunk
        self.readMoreURL = readMoreURL
        self.footnoteURL = footnoteURL
        self.font = font
        self.fontSize = fontSize
        self.characterDirection = characterDirection
    }

    public var body: some View {
        Text(string)
            .font(font)
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: characterDirection)
            .padding(.top, firstChunk ? topPadding : 0)
            .readableInsetsPadding(.horizontal)
    }

    private var string: AttributedString {
        let chunkText = text[chunk]

        var string = AttributedString(chunkText)
        for (index, footnoteRange) in footnoteRanges.enumerated() {
            if let range = string.range(from: footnoteRange, overallRange: chunk, overallText: text) {
                string[range].link = footnoteURL(index)
                // TODO: Should get footnote from environment.
                string[range].font = .footnote
                string[range].baselineOffset = baselineOffset
            }
        }

        for quranRange in quranRanges {
            if let range = string.range(from: quranRange, overallRange: chunk, overallText: text) {
                string[range].foregroundColor = .accentColor
            }
        }

        if let readMoreURL {
            var readMore = AttributedString("\n\(l("translation.text.read-more"))")
            readMore.foregroundColor = .accentColor
            readMore.link = readMoreURL
            readMore.font = .body
            string.append(readMore)
        }

        return string
    }
}
