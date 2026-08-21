//
//  QuranTextView.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

import NoorFont
import QuranKit
import QuranText
import SwiftUI

private let quranFontSize: CGFloat = 21

struct QuranTextFontOverride {
    let range: Range<String.Index>
    let fontName: FontName
}

/// Quran text rendered with the required Quran font.
public struct QuranTextView: View {
    // MARK: Lifecycle

    public init(_ text: QuranText) {
        self.init(text, fontName: .uthmanicHafs)
    }

    init(_ text: QuranText, fontName: FontName, fontOverrides: [QuranTextFontOverride] = []) {
        self.init(
            text,
            font: .custom(fontName, size: quranFontSize),
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
            attributedText[start ..< end].font = .custom(override.fontName, size: quranFontSize)
        }
        return attributedText
    }
}

extension Quran {
    var translationQuranFontName: FontName {
        self == .hafsIndoPak ? .indoPak : .uthmanicHafs
    }
}
