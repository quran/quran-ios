//
//  ReadingPreferences.swift
//
//
//  Created by Mohamed Afifi on 2023-02-14.
//

import Preferences
import Reading

public struct ReadingPreferences {
    public static let shared = ReadingPreferences()
    private init() {}

    private static let defaultQuranReading = Reading.hafs_1405
    private static let reading = PreferenceKey<Int>(key: "quranReading", defaultValue: defaultQuranReading.rawValue)

    @TransformedPreference(reading, transformer: .rawRepresentable(defaultValue: defaultQuranReading))
    public var reading: Reading
}
