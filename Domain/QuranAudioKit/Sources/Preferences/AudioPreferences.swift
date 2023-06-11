//
//  AudioPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Combine
import Preferences
import QuranAudio

public class AudioPreferences {
    public static let shared = AudioPreferences()

    private init() {}

    private static let audioEndKey = PreferenceKey<Int>(key: "audioEndKey", defaultValue: AudioEnd.juz.rawValue)

    @TransformedPreference(audioEndKey, transformer: .rawRepresentable(defaultValue: .juz))
    public var audioEnd: AudioEnd
}
