//
//  QuranTextView.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

import NoorFont
import QuranText
import SwiftUI

private let quranFontSize: CGFloat = 21

struct QuranTextFontOverride {
    let range: Range<String.Index>
    let quranFont: QuranFont
    let font: Font

    init(range: Range<String.Index>, quranFont: QuranFont, font: Font? = nil) {
        self.range = range
        self.quranFont = quranFont
        self.font = font ?? .custom(quranFont.fontName, size: quranFontSize)
    }
}

/// Quran text rendered with the required Quran font.
public struct QuranTextView: View {
    // MARK: Lifecycle

    public init(_ text: QuranText) {
        self.init(text, quranFont: .uthmanicHafs)
    }

    public init(_ text: QuranText, quranFont: QuranFont) {
        self.init(text, quranFont: quranFont, fontOverrides: [])
    }

    init(_ text: QuranText, quranFont: QuranFont, fontOverrides: [QuranTextFontOverride]) {
        self.init(
            text,
            font: .custom(quranFont.fontName, size: quranFontSize),
            highlighting: [],
            fontOverrides: fontOverrides
        )
    }

    init(
        _ text: QuranText,
        font: Font,
        highlighting: [HighlightingRange] = [],
        fontOverrides: [QuranTextFontOverride] = []
    ) {
        self.text = text
        self.font = font
        self.highlighting = highlighting
        self.fontOverrides = fontOverrides
    }

    // MARK: Public

    public var body: some View {
        Text(attributedText)
            .font(font)
    }

    // MARK: Private

    private let text: QuranText
    private let font: Font
    private let highlighting: [HighlightingRange]
    private let fontOverrides: [QuranTextFontOverride]

    private var attributedText: AttributedString {
        var attributedText = AttributedString(text.text)
        for highlight in highlighting {
            guard let start = AttributedString.Index(highlight.range.lowerBound, within: attributedText),
                  let end = AttributedString.Index(highlight.range.upperBound, within: attributedText)
            else {
                continue
            }
            if let foregroundColor = highlight.foregroundColor {
                attributedText[start ..< end].foregroundColor = foregroundColor
            }
            if let fontWeight = highlight.fontWeight {
                attributedText[start ..< end].font = font.weight(fontWeight)
            }
        }
        for override in fontOverrides {
            guard let start = AttributedString.Index(override.range.lowerBound, within: attributedText),
                  let end = AttributedString.Index(override.range.upperBound, within: attributedText)
            else {
                continue
            }
            attributedText[start ..< end].font = override.font
        }
        return attributedText
    }
}
