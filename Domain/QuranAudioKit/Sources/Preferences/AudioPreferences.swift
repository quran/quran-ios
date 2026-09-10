//
//  AudioPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Preferences
import QueuePlayer
import QuranAudio

public class AudioPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = AudioPreferences()

    @TransformedPreference(audioEndKey, transformer: .rawRepresentable(defaultValue: .juz))
    public var audioEnd: AudioEnd

    @Preference(audioPlaybackRateKey)
    public var playbackRate: Float

    @Preference(audioStreamingEnabledKey)
    public var streamingEnabled: Bool

    @TransformedPreference(audioVerseDelayKey, transformer: .rawRepresentable(defaultValue: VerseDelay.none))
    public var verseDelay: VerseDelay

    @TransformedPreference(audioRepetitionDelayKey, transformer: .rawRepresentable(defaultValue: .oneSecond))
    public var repetitionDelay: RepetitionDelay

    @TransformedPreference(audioVerseRunsKey, transformer: runsTransformer)
    public var verseRuns: Runs

    @TransformedPreference(audioListRunsKey, transformer: runsTransformer)
    public var listRuns: Runs

    // MARK: Private

    private static let audioEndKey = PreferenceKey<Int>(key: "audioEndKey", defaultValue: AudioEnd.juz.rawValue)
    private static let audioPlaybackRateKey = PreferenceKey<Float>(key: "audioPlaybackRate", defaultValue: 1.0)
    private static let audioStreamingEnabledKey = PreferenceKey<Bool>(key: "audioStreamingEnabled", defaultValue: false)
    private static let audioVerseDelayKey = PreferenceKey<Int>(key: "audioVerseDelay", defaultValue: VerseDelay.none.rawValue)
    private static let audioRepetitionDelayKey = PreferenceKey<Int>(key: "audioRepetitionDelay", defaultValue: RepetitionDelay.oneSecond.rawValue)
    private static let audioVerseRunsKey = PreferenceKey<Int>(key: "audioVerseRuns", defaultValue: 1)
    private static let audioListRunsKey = PreferenceKey<Int>(key: "audioListRuns", defaultValue: 1)
    private static let runsTransformer = PreferenceTransformer<Int, Runs>(
        rawToValue: {
            switch $0 {
            case 0: return .indefinite
            case 1...: return .finite($0)
            default: return .finite(1)
            }
        },
        valueToRaw: {
            switch $0 {
            case .finite(let count): return count
            case .indefinite: return 0
            }
        },
        isValidValue: {
            switch $0 {
            case .finite(let count): return count > 0
            case .indefinite: return true
            }
        }
    )
}
