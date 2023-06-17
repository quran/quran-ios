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
        for key in [Self.lastRevision.key, Self.lastChecked.key] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: Private

    private static let lastRevision = PreferenceKey<Int>(key: "audio-update.last-revision", defaultValue: 0)
    private static let lastChecked = PreferenceKey<Date?>(key: "audio-update.last-checked", defaultValue: nil)
}
