//
//  FontSizePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-11-24.
//

import Preferences
import QuranText

public struct FontSizePreferences {
    public static let shared = FontSizePreferences()
    private init() {}

    private static let defaultValue = FontSize.medium
    private static let translationFontSizeKey = PreferenceKey<Int>(key: "translationFontSize", defaultValue: defaultValue.rawValue)
    private static let arabicFontSizeKey = PreferenceKey<Int>(key: "arabicFont", defaultValue: defaultValue.rawValue)

    @TransformedPreference(translationFontSizeKey, transformer: .rawRepresentable(defaultValue: defaultValue))
    public var translationFontSize: FontSize

    @TransformedPreference(arabicFontSizeKey, transformer: .rawRepresentable(defaultValue: defaultValue))
    public var arabicFontSize: FontSize
}
