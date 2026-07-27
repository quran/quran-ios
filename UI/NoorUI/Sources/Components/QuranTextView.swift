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

/// Quran text rendered with the required Quran font.
public struct QuranTextView: View {
    // MARK: Lifecycle

    public init(_ text: QuranText) {
        self.init(text, font: .custom(.quran, size: quranFontSize), highlighting: [])
    }

    init(_ text: QuranText, font: Font, highlighting: [HighlightingRange] = []) {
        self.text = text
        self.font = font
        self.highlighting = highlighting
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
        return attributedText
    }
}
