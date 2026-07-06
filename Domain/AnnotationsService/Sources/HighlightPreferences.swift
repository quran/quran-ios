//
//  HighlightPreferences.swift
//
//
//  Created by QuranEngine on 2026-07-06.
//

import Preferences
import QuranAnnotations

public struct HighlightPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = HighlightPreferences()

    @TransformedPreference(lastUsedNoteHighlightColorKey, transformer: .rawRepresentable(defaultValue: defaultLastUsedNoteHighlightColor))
    public var lastUsedHighlightColor: HighlightColor

    // MARK: Private

    private static let defaultLastUsedNoteHighlightColor = HighlightColor.red
    private static let lastUsedNoteHighlightColorKey = PreferenceKey<Int>(
        key: "lastUsedNoteHighlightColor",
        defaultValue: defaultLastUsedNoteHighlightColor.rawValue
    )
}
