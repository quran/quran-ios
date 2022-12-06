//
//  AudioPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Combine
import Foundation
import OrderedCollections
import Preferences

@available(iOS 13.0, *)
public class AudioPreferences {
    public static let shared = AudioPreferences()

    private init() {}

    private static let lastSelectedReciterId = PreferenceKey<Int>(key: "LastSelectedQariId", defaultValue: 41)
    private static let audioEndKey = PreferenceKey<Int>(key: "audioEndKey", defaultValue: AudioEnd.juz.rawValue)
    private static let recentReciterIds = PreferenceKey<[Int]>(key: "recentRecitersIdsKey", defaultValue: [])
    private static let recentReciterIdsTransfomer = PreferenceTransformer<[Int], OrderedSet<Int>>(
        rawToValue: { OrderedSet($0) },
        valueToRaw: { Array($0) }
    )

    @TransformedPreference(audioEndKey, transformer: .rawRepresentable(defaultValue: .juz))
    public var audioEnd: AudioEnd

    @Preference(lastSelectedReciterId)
    public var lastSelectedReciterId: Int

    @TransformedPreference(recentReciterIds, transformer: recentReciterIdsTransfomer)
    public var recentReciterIds: OrderedSet<Int>
}
