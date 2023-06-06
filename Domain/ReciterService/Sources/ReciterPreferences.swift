//
//  ReciterPreferences.swift
//
//
//  Created by Mohamed Afifi on 2023-06-04.
//

import Combine
import Foundation
import OrderedCollections
import Preferences

public class ReciterPreferences {
    public static let shared = ReciterPreferences()

    private init() {}

    private static let lastSelectedReciterId = PreferenceKey<Int>(key: "LastSelectedQariId", defaultValue: 41)
    private static let recentReciterIds = PreferenceKey<[Int]>(key: "recentRecitersIdsKey", defaultValue: [])
    private static let recentReciterIdsTransfomer = PreferenceTransformer<[Int], OrderedSet<Int>>(
        rawToValue: { OrderedSet($0) },
        valueToRaw: { Array($0) }
    )

    @Preference(lastSelectedReciterId)
    public var lastSelectedReciterId: Int

    @TransformedPreference(recentReciterIds, transformer: recentReciterIdsTransfomer)
    public var recentReciterIds: OrderedSet<Int>
}
