//
//  FontSizePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-11-24.
//

import Preferences
import QuranText

public struct FontSizePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = FontSizePreferences()

    @TransformedPreference(translationFontSizeKey, transformer: .rawRepresentable(defaultValue: defaultValue))
    public var translationFontSize: FontSize

    @TransformedPreference(arabicFontSizeKey, transformer: .rawRepresentable(defaultValue: defaultValue))
    public var arabicFontSize: FontSize

    // MARK: Private

    private static let defaultValue = FontSize.medium
    private static let translationFontSizeKey = PreferenceKey<Int>(key: "translationFontSize", defaultValue: defaultValue.rawValue)
    private static let arabicFontSizeKey = PreferenceKey<Int>(key: "arabicFont", defaultValue: defaultValue.rawValue)
}
