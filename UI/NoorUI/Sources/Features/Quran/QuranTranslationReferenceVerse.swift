//
//  QuranTranslationReferenceVerse.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import Localization
import QuranKit
import QuranText
import SwiftUI
import UIx

public struct QuranTranslationReferenceVerse: View {
    @Environment(\.layoutDirection) private var layoutDirection
    @ScaledMetric var verseTopPadding = QuranTranslationSpacing.verseTop
    @ScaledMetric var translationTopPadding = QuranTranslationSpacing.translationTop

    let reference: AyahNumber
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection
    let verseNumber: QuranVerseNumber?

    /// - Parameter verseNumber: The verse-number capsule that starts the verse, shown at the start of the line.
    ///   Pass it only when this is the verse's first translation.
    public init(reference: AyahNumber, fontSize: FontSize, characterDirection: Locale.LanguageDirection, verseNumber: QuranVerseNumber? = nil) {
        self.reference = reference
        self.fontSize = fontSize
        self.characterDirection = characterDirection
        self.verseNumber = verseNumber
    }

    public var body: some View {
        QuranVerseNumberText(
            text: AttributedString(lFormat("translation.text.see-referenced-verse", reference.ayah)),
            verseNumber: verseNumber,
            characterDirection: characterDirection,
            verseNumberLayoutDirection: layoutDirection
        )
        .font(.body)
        .dynamicTypeSize(fontSize.dynamicTypeSize)
        .textAlignment(follows: characterDirection)
        .padding(.top, verseNumber == nil ? translationTopPadding : verseTopPadding)
        .readableInsetsPadding(.horizontal)
    }
}
