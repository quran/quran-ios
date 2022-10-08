//
//  RecentSearchPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Foundation
import Preferences
import Utilities

final class RecentSearchPreferences {
    static let shared = RecentSearchPreferences()
    private init() {}

    private static let searchRecentItems = PreferenceKey<[String]>(key: "com.quran.searchRecentItems", defaultValue: [])
    private static let searchRecentItemsTransfomer = PreferenceTransformer<[String], [String]>(
        rawToValue: { $0.orderedUnique() },
        valueToRaw: { $0 }
    )

    @TransformedPreference(searchRecentItems, transformer: searchRecentItemsTransfomer)
    var recentSearchItems: [String]
}
