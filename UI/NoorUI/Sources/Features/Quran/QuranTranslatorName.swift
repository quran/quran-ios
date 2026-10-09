//
//  QuranTranslatorName.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import QuranText
import SwiftUI
import UIx

public struct QuranTranslatorName: View {
    @ScaledMetric var topPadding = QuranTranslationSpacing.translatorNameTop

    let name: String
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection

    public init(name: String, fontSize: FontSize, characterDirection: Locale.LanguageDirection) {
        self.name = name
        self.fontSize = fontSize
        self.characterDirection = characterDirection
    }

    public var body: some View {
        Text(verbatim: "- \(name)")
            .themedSecondaryForeground()
            .font(.footnote)
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: characterDirection)
            .padding(.top, topPadding)
            .readableInsetsPadding(.horizontal)
    }
}
