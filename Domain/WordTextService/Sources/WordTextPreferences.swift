//
//  WordTextPreferences.swift
//
//
//  Created by Mohamed Afifi on 2023-06-08.
//

import Preferences
import QuranText

public struct WordTextPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = WordTextPreferences()

    @TransformedPreference(wordTextType, transformer: .rawRepresentable(defaultValue: defaultWordTextType))
    public var wordTextType: WordTextType

    @Preference(isWordPointerActive)
    public var isWordPointerActive: Bool

    // MARK: Private

    private static let defaultWordTextType = WordTextType.translation
    private static let wordTextType = PreferenceKey<Int>(key: "wordTranslationType", defaultValue: defaultWordTextType.rawValue)
    private static let isWordPointerActive = PreferenceKey<Bool>(key: "isWordPointerActive", defaultValue: false)
}
