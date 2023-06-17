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
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = RecentSearchPreferences()

    @TransformedPreference(searchRecentItems, transformer: searchRecentItemsTransfomer)
    var recentSearchItems: [String]

    // MARK: Private

    private static let searchRecentItems = PreferenceKey<[String]>(key: "com.quran.searchRecentItems", defaultValue: [])
    private static let searchRecentItemsTransfomer = PreferenceTransformer<[String], [String]>(
        rawToValue: { $0.orderedUnique() },
        valueToRaw: { $0 }
    )
}
