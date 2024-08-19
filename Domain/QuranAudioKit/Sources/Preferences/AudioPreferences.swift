//
//  AudioPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Preferences
import QuranAudio

public class AudioPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = AudioPreferences()

    @TransformedPreference(audioEndKey, transformer: .rawRepresentable(defaultValue: .juz))
    public var audioEnd: AudioEnd

    // MARK: Private

    private static let audioEndKey = PreferenceKey<Int>(key: "audioEndKey", defaultValue: AudioEnd.juz.rawValue)
}
