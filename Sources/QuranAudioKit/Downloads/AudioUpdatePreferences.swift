//
//  AudioUpdatePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Foundation
import Preferences

protocol AudioUpdatePreferences: AnyObject {
    var lastRevision: Int { get set }
    var lastChecked: Date? { get set }
}

final class DefaultAudioUpdatePreferences: AudioUpdatePreferences {
    private static let lastRevision = PreferenceKey<Int>(key: "audio-update.last-revision", defaultValue: 0)
    private static let lastChecked = PreferenceKey<Date?>(key: "audio-update.last-checked", defaultValue: nil)

    private let preferences: Preferences

    init(userDefaults: UserDefaults) {
        preferences = Preferences(userDefaults: userDefaults)
    }

    var lastRevision: Int {
        get {
            preferences.valueForKey(Self.lastRevision)
        }
        set {
            preferences.setValue(newValue, forKey: Self.lastRevision)
        }
    }

    var lastChecked: Date? {
        get {
            preferences.valueForKey(Self.lastChecked)
        }
        set {
            preferences.setValue(newValue, forKey: Self.lastChecked)
        }
    }
}
