//
//  AudioPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Combine
import Foundation
import Preferences

public protocol SelectedReciterPreferences {
    var lastSelectedReciterId: Int { get }
}

public protocol WriteableSelectedReciterPreferences: AnyObject, SelectedReciterPreferences {
    var lastSelectedReciterId: Int { get set }
}

@available(iOS 13.0, *)
public class AudioPreferences: WriteableSelectedReciterPreferences {
    private static let lastSelectedReciterId = PreferenceKey<Int>(key: "LastSelectedQariId", defaultValue: 41)
    private static let audioEndKey = PreferenceKey<Int>(key: "audioEndKey", defaultValue: AudioEnd.juz.rawValue)

    private let preferences: Preferences
    private let audioEndPreferences: PreferencesValue<Int>

    public init(userDefaults: UserDefaults) {
        preferences = Preferences(userDefaults: userDefaults)
        audioEndPreferences = PreferencesValue(userDefaults: userDefaults, key: Self.audioEndKey)
    }

    public var lastSelectedReciterId: Int {
        get {
            preferences.valueForKey(Self.lastSelectedReciterId)
        }
        set {
            preferences.setValue(newValue, forKey: Self.lastSelectedReciterId)
        }
    }

    public var audioEndPublisher: AnyPublisher<AudioEnd, Never> {
        audioEndPreferences.publisher
            .map { AudioEnd(rawValue: $0) ?? .juz }
            .eraseToAnyPublisher()
    }

    public var audioEnd: AudioEnd {
        get {
            AudioEnd(rawValue: audioEndPreferences.value) ?? .juz
        }
        set {
            audioEndPreferences.value = newValue.rawValue
        }
    }
}
