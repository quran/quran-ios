//
//  Preferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

import Foundation

public struct Preferences {
    public let userDefaults: UserDefaults
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public func valueForKey<T>(_ key: PreferenceKey<T>) -> T {
        let value = userDefaults.object(forKey: key.key)
        return (value as? T) ?? key.defaultValue
    }

    public func setValue<T>(_ value: T?, forKey key: PreferenceKey<T>) {
        guard let value = value else {
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

    public func removeValueForKey<T>(_ key: PreferenceKey<T?>) {
        userDefaults.removeObject(forKey: key.key)
    }
}

extension Preferences {
    public func serializedValueForKey<T: NSCoding>(_ key: PreferenceKey<T>) -> T {
        let preferenceKey = PreferenceKey<Data?>(key.key, nil)
        guard let data = valueForKey(preferenceKey) else {
            return key.defaultValue
        }
        let object = NSKeyedUnarchiver.unarchiveObject(with: data)
        guard let value = object as? T else {
            fatalError("Cannot unarchive perference data for key '\(key.key)'")
        }
        return value
    }

    public func setSerializedValue<T: NSCoding>(_ value: T?, forKey key: PreferenceKey<T>) {
        let preferenceKey = PreferenceKey<Data?>(key.key, nil)

        let data: Data?
        if let value = value {
            data = NSKeyedArchiver.archivedData(withRootObject: value)
        } else {
            data = nil
        }
        setValue(data, forKey: preferenceKey)
    }
}
