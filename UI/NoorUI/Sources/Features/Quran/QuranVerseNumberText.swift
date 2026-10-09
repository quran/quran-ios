//
//  QuranVerseNumberText.swift
//
//
//  Created by Mohamed Afifi on 2026-10-09.
//

import SwiftUI

/// Translation text whose first line starts with the verse-number capsule.
///
/// The capsule floats at the start of the first line: the left edge for left-to-right text and the
/// right edge for right-to-left text. An invisible run as wide as the capsule starts the text, so the
/// first line flows after the capsule and later lines use the full width. The capsule's width is
/// computed from its fonts, so the text is indented correctly in the first layout pass.
///
/// Place it in a left-to-right layout, as `textAlignment(follows:)` does.
struct QuranVerseNumberText: View {
    // MARK: Internal

    let text: AttributedString
    let verseNumber: QuranVerseNumber?
    let characterDirection: Locale.LanguageDirection
    /// The layout direction for the capsule's own content.
    let verseNumberLayoutDirection: LayoutDirection

    var body: some View {
        if let verseNumber {
            let verseNumberSize = verseNumber.inlineSize(dynamicTypeSize: dynamicTypeSize, legibilityWeight: legibilityWeight)
            Text(Self.indented(text, by: verseNumberSize.width + spacing, characterDirection: characterDirection))
                .overlay(alignment: Alignment(horizontal: horizontalAlignment, vertical: .firstTextBaseline)) {
                    verseNumber
                        .inline(size: verseNumberSize, maximumHorizontalOutset: spacing / 2)
                        .environment(\.layoutDirection, verseNumberLayoutDirection)
                        // Read the verse number before its text.
                        .accessibilitySortPriority(1)
                }
                .accessibilityElement(children: .contain)
        } else {
            Text(text)
        }
    }

    /// Starts `text` with an invisible run `width` wide. Its directional mark and space aren't spoken by VoiceOver.
    static func indented(_ text: AttributedString, by width: CGFloat, characterDirection: Locale.LanguageDirection) -> AttributedString {
        // The directional mark makes the paragraph start on the capsule's side even when the text
        // starts with a character of the other direction.
        var mark = AttributedString(characterDirection == .rightToLeft ? "\u{200F}" : "\u{200E}")
        mark.font = indentFont

        var indent = AttributedString(" ")
        indent.font = indentFont
        indent.kern = width

        return mark + indent + text
    }

    // MARK: Private

    /// A tiny font keeps the indent's own space negligible next to its kerning and never makes the line taller.
    private static let indentFont = Font.system(size: 1)

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.legibilityWeight) private var legibilityWeight
    @ScaledMetric private var spacing = 8

    private var horizontalAlignment: HorizontalAlignment {
        characterDirection == .rightToLeft ? .trailing : .leading
    }
}
