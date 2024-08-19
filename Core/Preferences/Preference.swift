//
//  Preference.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import Combine

@propertyWrapper
public final class Preference<T> {
    // MARK: Lifecycle

    public init(_ key: PreferenceKey<T>, preferences: Preferences = .shared) {
        self.key = key
        self.preferences = preferences
    }

    // MARK: Public

    public var wrappedValue: T {
        get { preferences.valueForKey(key) }
        set { preferences.setValue(newValue, forKey: key) }
    }

    public var projectedValue: AnyPublisher<T, Never> {
        preferences.notifications
            .compactMap { [weak self] key in
                if let self, key == self.key.key {
                    return wrappedValue
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: Private

    private let key: PreferenceKey<T>
    private let preferences: Preferences
}

@propertyWrapper
public final class TransformedPreference<Raw, T> {
    // MARK: Lifecycle

    public init(
        _ key: PreferenceKey<Raw>,
        preferences: Preferences = .shared,
        transformer: PreferenceTransformer<Raw, T>
    ) {
        preference = Preference(key, preferences: preferences)
        self.transformer = transformer
    }

    // MARK: Public

    public var wrappedValue: T {
        get { transformer.rawToValue(preference.wrappedValue) }
        set { preference.wrappedValue = transformer.valueToRaw(newValue) }
    }

    public var projectedValue: AnyPublisher<T, Never> {
        preference.projectedValue
            .map(transformer.rawToValue)
            .eraseToAnyPublisher()
    }

    // MARK: Private

    private let preference: Preference<Raw>
    private let transformer: PreferenceTransformer<Raw, T>
}
