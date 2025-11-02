//
//  AudioPreferences+PlaybackRate.swift
//  QuranEngine
//
//  Created by Adnan on 02/11/2025.
//

import Foundation
import Preferences

// Single, file-scoped key instance (avoids DEBUG duplicate-key fatalError)
private let audioPlaybackRateKey = PreferenceKey<Float>(key: "audio.playbackRate", defaultValue: 1.0)

public extension AudioPreferences {
    var playbackRate: Float {
        get { Preferences.shared.valueForKey(audioPlaybackRateKey) }
        set { Preferences.shared.setValue(newValue, forKey: audioPlaybackRateKey) }
    }
}
