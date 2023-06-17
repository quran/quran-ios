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
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = ReciterPreferences()

    @Preference(lastSelectedReciterId)
    public var lastSelectedReciterId: Int

    @TransformedPreference(recentReciterIds, transformer: recentReciterIdsTransfomer)
    public var recentReciterIds: OrderedSet<Int>

    // MARK: Private

    private static let lastSelectedReciterId = PreferenceKey<Int>(key: "LastSelectedQariId", defaultValue: 41)
    private static let recentReciterIds = PreferenceKey<[Int]>(key: "recentRecitersIdsKey", defaultValue: [])
    private static let recentReciterIdsTransfomer = PreferenceTransformer<[Int], OrderedSet<Int>>(
        rawToValue: { OrderedSet($0) },
        valueToRaw: { Array($0) }
    )
}
