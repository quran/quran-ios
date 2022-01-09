//
//  SelectedReciterPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Foundation
import Preferences

public protocol SelectedReciterPreferences {
    var lastSelectedReciterId: Int { get }
}

public protocol WriteableSelectedReciterPreferences: AnyObject, SelectedReciterPreferences {
    var lastSelectedReciterId: Int { get set }
}

public class DefaultsSelectedReciterPreferences: WriteableSelectedReciterPreferences {
    private static let lastSelectedReciterId = PreferenceKey<Int>(key: "LastSelectedQariId", defaultValue: 41)
    private let preferences: Preferences

    public init(userDefaults: UserDefaults) {
        preferences = Preferences(userDefaults: userDefaults)
    }

    public var lastSelectedReciterId: Int {
        get {
            preferences.valueForKey(Self.lastSelectedReciterId)
        }
        set {
            preferences.setValue(newValue, forKey: Self.lastSelectedReciterId)
        }
    }
}
