//
//  QuranContentStatePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-11-24.
//

import Foundation
import Preferences

public protocol QuranContentStatePreferences {
    var quranMode: QuranMode { get }
    var wordTextType: WordTextType { get }
}

public protocol WriteableQuranContentStatePreferences: AnyObject, QuranContentStatePreferences {
    var quranMode: QuranMode { get set }
    var wordTextType: WordTextType { get set }
}

public class DefaultsQuranContentStatePreferences: WriteableQuranContentStatePreferences {
    private static let defaultWordTextType = WordTextType.translation
    private static let wordTextType = PreferenceKey<Int>(key: "wordTranslationType", defaultValue: defaultWordTextType.rawValue)
    private static let showQuranTranslationView = PreferenceKey<Bool>(key: "showQuranTranslationView", defaultValue: false)
    private let preferences: Preferences

    public init(userDefaults: UserDefaults) {
        preferences = Preferences(userDefaults: userDefaults)
    }

    public var quranMode: QuranMode {
        get {
            preferences.valueForKey(Self.showQuranTranslationView) ? .translation : .arabic
        }
        set {
            preferences.setValue(newValue == .translation, forKey: Self.showQuranTranslationView)
        }
    }

    public var wordTextType: WordTextType {
        get {
            let type = WordTextType(rawValue: preferences.valueForKey(Self.wordTextType))
            return type ?? Self.defaultWordTextType
        }
        set {
            preferences.setValue(newValue.rawValue, forKey: Self.wordTextType)
        }
    }
}
