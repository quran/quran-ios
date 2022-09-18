//
//  QuranContentStatePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-11-24.
//

import Foundation
import Preferences

public struct QuranContentStatePreferences {
    public static let shared = QuranContentStatePreferences()
    private init() {}

    private static let defaultWordTextType = WordTextType.translation
    private static let wordTextType = PreferenceKey<Int>(key: "wordTranslationType", defaultValue: defaultWordTextType.rawValue)
    private static let showQuranTranslationView = PreferenceKey<Bool>(key: "showQuranTranslationView", defaultValue: false)

    private static let quranModeTransfomer = PreferenceTransformer<Bool, QuranMode>(
        rawToValue: { $0 ? .translation : .arabic },
        valueToRaw: { $0 == .translation })

    @TransformedPreference(showQuranTranslationView, transformer: quranModeTransfomer)
    public var quranMode: QuranMode

    @TransformedPreference(wordTextType, transformer: .rawRepresentable(defaultValue: defaultWordTextType))
    public var wordTextType: WordTextType
}
