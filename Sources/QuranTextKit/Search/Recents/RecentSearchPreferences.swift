//
//  RecentSearchPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Foundation
import Preferences

protocol RecentSearchPreferences: AnyObject {
    var recentSearchItems: [String] { get set }
}

final class DefaultRecentSearchPreferences: RecentSearchPreferences {
    private static let searchRecentItems = PreferenceKey<NSOrderedSet>(key: "com.quran.searchRecentItems", defaultValue: [])

    private let preferences: Preferences

    init(userDefaults: UserDefaults) {
        preferences = Preferences(userDefaults: userDefaults)
    }

    var recentSearchItems: [String] {
        get {
            let recents = preferences.serializedValueForKey(Self.searchRecentItems)
            return recents.map { $0 as! String } // swiftlint:disable:this force_cast
        }
        set {
            preferences.setSerializedValue(NSOrderedSet(array: newValue), forKey: Self.searchRecentItems)
        }
    }
}
