//
//  AudioPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Combine
import Foundation
import Preferences

@available(iOS 13.0, *)
public class AudioPreferences {
    public static let shared = AudioPreferences()
    private init() {}

    private static let lastSelectedReciterId = PreferenceKey<Int>(key: "LastSelectedQariId", defaultValue: 41)
    private static let audioEndKey = PreferenceKey<Int>(key: "audioEndKey", defaultValue: AudioEnd.juz.rawValue)

    @TransformedPreference(audioEndKey, transformer: .rawRepresentable(defaultValue: .juz))
    public var audioEnd: AudioEnd

    @Preference(lastSelectedReciterId)
    public var lastSelectedReciterId: Int
}
