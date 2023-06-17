//
//  ReadingPreferences.swift
//
//
//  Created by Mohamed Afifi on 2023-02-14.
//

import Preferences
import QuranKit

public struct ReadingPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = ReadingPreferences()

    @TransformedPreference(reading, transformer: .rawRepresentable(defaultValue: defaultQuranReading))
    public var reading: Reading

    // MARK: Private

    private static let defaultQuranReading = Reading.hafs_1405
    private static let reading = PreferenceKey<Int>(key: "quranReading", defaultValue: defaultQuranReading.rawValue)
}
