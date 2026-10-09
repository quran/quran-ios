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
    @Environment(\.layoutDirection) private var layoutDirection
    @ScaledMetric var verseTopPadding = QuranTranslationSpacing.verseTop
    @ScaledMetric var translationTopPadding = QuranTranslationSpacing.translationTop
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
    let verseNumber: QuranVerseNumber?

    /// - Parameter verseNumber: The verse-number capsule that starts the verse, shown at the start of the first line.
    ///   Pass it only to the first chunk of the verse's first translation.
    public init(text: String, chunk: Range<String.Index>, footnoteRanges: [Range<String.Index>], quranRanges: [Range<String.Index>], firstChunk: Bool, readMoreURL: URL?, footnoteURL: @escaping (Int) -> URL, font: Font, fontSize: FontSize, characterDirection: Locale.LanguageDirection, verseNumber: QuranVerseNumber? = nil) {
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
        self.verseNumber = verseNumber
    }

    public var body: some View {
        QuranVerseNumberText(
            text: string,
            verseNumber: verseNumber,
            characterDirection: characterDirection,
            verseNumberLayoutDirection: layoutDirection
        )
        .font(font)
        .dynamicTypeSize(fontSize.dynamicTypeSize)
        .textAlignment(follows: characterDirection)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }

    private var topPadding: CGFloat {
        if verseNumber != nil {
            verseTopPadding
        } else if firstChunk {
            translationTopPadding
        } else {
            0
        }
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
