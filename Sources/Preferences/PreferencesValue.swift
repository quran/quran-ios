//
//  PreferencesValue.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import Combine
import Foundation

@available(iOS 13.0, *)
public final class PreferencesValue<Value> {
    private let preferences: Preferences
    private let key: PreferenceKey<Value>
    private lazy var _publisher = CurrentValueSubject<Value, Never>(value)
    public init(userDefaults: UserDefaults, key: PreferenceKey<Value>) {
        preferences = Preferences(userDefaults: userDefaults)
        self.key = key
    }

    public var value: Value {
        get {
            preferences.valueForKey(key)
        }
        set {
            preferences.setValue(newValue, forKey: key)
            _publisher.send(newValue)
        }
    }

    public var publisher: AnyPublisher<Value, Never> {
        _publisher.eraseToAnyPublisher()
    }

    public func reset() {
        preferences.setValue(nil, forKey: key)
        _publisher.send(value)
    }
}
