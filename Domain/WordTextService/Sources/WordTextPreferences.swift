//
//  WordTextPreferences.swift
//
//
//  Created by Mohamed Afifi on 2023-06-08.
//

import Preferences

public struct WordTextPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = WordTextPreferences()

    @TransformedPreference(wordTextType, transformer: .rawRepresentable(defaultValue: defaultWordTextType))
    public var wordTextType: WordTextType

    // MARK: Private

    private static let defaultWordTextType = WordTextType.translation
    private static let wordTextType = PreferenceKey<Int>(key: "wordTranslationType", defaultValue: defaultWordTextType.rawValue)
}
