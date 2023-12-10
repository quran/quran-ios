//
//  AudioUpdatePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Foundation
import Preferences

final class AudioUpdatePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = AudioUpdatePreferences()

    @Preference(lastRevision) var lastRevision: Int
    @Preference(lastChecked) var lastChecked: Date?

    func reset() {
        Preferences.shared.removeValueForKey(Self.lastRevision)
        Preferences.shared.removeValueForKey(Self.lastChecked)
    }

    // MARK: Private

    private static let lastRevision = PreferenceKey<Int>(key: "audio-update.last-revision", defaultValue: 0)
    private static let lastChecked = PreferenceKey<Date?>(key: "audio-update.last-checked", defaultValue: nil)
}
