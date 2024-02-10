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
    @ScaledMetric var topPadding = 10

    let reference: AyahNumber
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection

    public init(reference: AyahNumber, fontSize: FontSize, characterDirection: Locale.LanguageDirection) {
        self.reference = reference
        self.fontSize = fontSize
        self.characterDirection = characterDirection
    }

    public var body: some View {
        Text(lFormat("translation.text.see-referenced-verse", reference.ayah))
            .font(.body)
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: characterDirection)
            .padding(.top, topPadding)
            .readableInsetsPadding(.horizontal)
    }
}
