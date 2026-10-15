//
//  PlainTextPartView.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import SwiftUI

/// A `Text` whose paragraph is right-to-left leaves its trailing whitespace out of its width,
/// which would join it to the next `MultipartText` part, so that whitespace renders as its own `Text`.
struct PlainTextPartView: View {
    // MARK: Internal

    let text: String

    var body: some View {
        let (content, trailingSpace) = Self.splittingTrailingSpace(text)
        if trailingSpace.isEmpty {
            Text(text)
        } else {
            HStack(spacing: 0) {
                Text(content)
                Text(trailingSpace)
            }
        }
    }

    /// Splits trailing whitespace and bidi controls, such as the isolates `String(format:)` puts around
    /// arguments, off the end of the text. Splits between characters, so clusters such as tag-sequence flags
    /// and ZWJ joins stay whole. Text that is empty or only whitespace isn't split.
    static func splittingTrailingSpace(_ text: String) -> (content: String, trailingSpace: String) {
        let isTrailingSpace = { (character: Character) in character.unicodeScalars.allSatisfy(Self.isTrailingSpace) }
        guard let lastContent = text.lastIndex(where: { !isTrailingSpace($0) }) else {
            return (text, "")
        }
        let trailingStart = text.index(after: lastContent)
        return (String(text[..<trailingStart]), String(text[trailingStart...]))
    }

    // MARK: Private

    private static let bidiControls: Set<Unicode.Scalar> = [
        "\u{200E}", "\u{200F}", // LRM, RLM
        "\u{202A}", "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}", // embeddings and overrides
        "\u{2066}", "\u{2067}", "\u{2068}", "\u{2069}", // isolates
    ]

    private static func isTrailingSpace(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.isWhitespace || bidiControls.contains(scalar)
    }
}
