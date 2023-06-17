//
//  PreferencesValue.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import Combine
import Foundation

@available(iOS 13.0, *)
@propertyWrapper
public final class Preference<T> {
    // MARK: Lifecycle

    public init(_ key: PreferenceKey<T>, preferences: Preferences = Preferences(userDefaults: .standard)) {
        self.key = key
        self.preferences = preferences
        observer = PreferenceObserver(self)
    }

    // MARK: Public

    public var wrappedValue: T {
        get { preferences.valueForKey(key) }
        set { preferences.setValue(newValue, forKey: key) }
    }

    public var projectedValue: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: Private

    private final class PreferenceObserver<T>: NSObject {
        // MARK: Lifecycle

        init(_ preference: Preference<T>) {
            key = preference.key
            userDefaults = preference.preferences.userDefaults
            self.preference = preference
            super.init()
            preference.preferences.userDefaults.addObserver(
                self,
                forKeyPath: preference.key.key,
                options: .new,
                context: &observerContext
            )
        }

        deinit {
            userDefaults.removeObserver(
                self,
                forKeyPath: key.key,
                context: &observerContext
            )
        }

        // MARK: Public

        override public func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard let preference else {
                return
            }
            if context == &observerContext {
                preference.subject.send(preference.wrappedValue)
            } else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            }
        }

        // MARK: Internal

        weak var preference: Preference<T>?

        // MARK: Private

        private var observerContext = 0

        private let key: PreferenceKey<T>
        private let userDefaults: UserDefaults
    }

    private let key: PreferenceKey<T>
    private let preferences: Preferences
    private var observer: PreferenceObserver<T>?
    private let subject = PassthroughSubject<T, Never>()
}

@available(iOS 13.0, *)
@propertyWrapper
public final class TransformedPreference<Raw, T> {
    // MARK: Lifecycle

    public init(
        _ key: PreferenceKey<Raw>,
        preferences: Preferences = Preferences(userDefaults: .standard),
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
