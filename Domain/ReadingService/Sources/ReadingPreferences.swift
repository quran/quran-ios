//
//  ReadingPreferences.swift
//
//
//  Created by Mohamed Afifi on 2023-02-14.
//

import Combine
import Preferences
import QuranKit
import Utilities

public struct ReadingPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = ReadingPreferences()

    @TransformedPreference(reading, transformer: .rawRepresentable(defaultValue: defaultQuranReading))
    public var reading: Reading

    /// The current reading, then each reading the user switches to.
    public func readings() -> Utilities.AsyncPublisher<Reading> {
        // Deferred reads the current reading when iteration starts, not when this is called.
        Deferred { [self] in $reading.prepend(reading) }.values()
    }

    // MARK: Private

    private static let defaultQuranReading = Reading.hafs_1405
    private static let reading = PreferenceKey<Int>(key: "quranReading", defaultValue: defaultQuranReading.rawValue)
}
