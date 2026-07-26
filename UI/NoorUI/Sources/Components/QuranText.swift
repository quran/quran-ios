//
//  QuranText.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

import NoorFont
import SwiftUI

private let quranFontSize: CGFloat = 21

/// Quran text rendered with the required Quran font.
public struct QuranText: View {
    // MARK: Lifecycle

    public init(_ text: String) {
        self.init(text, font: .custom(.quran, size: quranFontSize))
    }

    init(_ text: String, font: Font) {
        self.text = text
        self.font = font
    }

    // MARK: Public

    public var body: some View {
        Text(verbatim: text)
            .font(font)
    }

    // MARK: Private

    private let text: String
    private let font: Font
}
