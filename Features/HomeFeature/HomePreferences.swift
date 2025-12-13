//
//  HomePreferences.swift
//
//
//  Created by QuranEngine on 2024.
//

import Foundation
import Preferences

struct HomePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = HomePreferences()

    @TransformedPreference(surahSortOrder, transformer: .rawRepresentable(defaultValue: .ascending))
    var surahSortOrder: SurahSortOrder

    // MARK: Private

    private static let surahSortOrder = PreferenceKey<Int>(key: "surahSortOrder", defaultValue: SurahSortOrder.ascending.rawValue)
}
