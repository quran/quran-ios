//
//  WordTextPreferences.swift
//
//
//  Created by Mohamed Afifi on 2023-06-08.
//

import Foundation
import Preferences

public struct WordTextPreferences {
    public static let shared = WordTextPreferences()
    private init() {}

    private static let defaultWordTextType = WordTextType.translation
    private static let wordTextType = PreferenceKey<Int>(key: "wordTranslationType", defaultValue: defaultWordTextType.rawValue)

    @TransformedPreference(wordTextType, transformer: .rawRepresentable(defaultValue: defaultWordTextType))
    public var wordTextType: WordTextType
}
