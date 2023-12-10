//
//  Preferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

import Combine
import Foundation

public final class Preferences {
    // MARK: Lifecycle

    private init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    // MARK: Public

    public static var shared = Preferences(userDefaults: .standard)

    public var notifications: AnyPublisher<String, Never> {
        notificationsSubject.eraseToAnyPublisher()
    }

    public func valueForKey<T>(_ key: PreferenceKey<T>) -> T {
        let value = userDefaults.object(forKey: key.key)
        return (value as? T) ?? key.defaultValue
    }

    public func setValue<T>(_ value: T?, forKey key: PreferenceKey<T>) {
        defer {
            notificationsSubject.send(key.key)
        }

        guard let value else {
            userDefaults.removeObject(forKey: key.key)
            return
        }

        if let value = value as? Int {
            userDefaults.set(value, forKey: key.key)
        } else if let value = value as? Float {
            userDefaults.set(value, forKey: key.key)
        } else if let value = value as? Double {
            userDefaults.set(value, forKey: key.key)
        } else if let value = value as? Bool {
            userDefaults.set(value, forKey: key.key)
        } else if let value = value as? URL {
            userDefaults.set(value, forKey: key.key)
        } else if let value = value as? Data {
            userDefaults.set(value, forKey: key.key)
        } else {
            userDefaults.set(value, forKey: key.key)
        }
    }

    public func removeValueForKey(_ key: PreferenceKey<some Any>) {
        setValue(nil, forKey: key)
    }

    // MARK: Private

    private let userDefaults: UserDefaults
    private let notificationsSubject = PassthroughSubject<String, Never>()
}
