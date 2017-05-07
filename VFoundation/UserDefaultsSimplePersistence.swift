//
//  UserDefaultsSimplePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

public struct UserDefaultsSimplePersistence: SimplePersistence {

    public let userDefaults: UserDefaults
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public func valueForKey<T>(_ key: PersistenceKey<T>) -> T {
        let value = userDefaults.object(forKey: key.key)
        return (value as? T) ?? key.defaultValue
    }

    public func setValue<T>(_ value: T?, forKey key: PersistenceKey<T>) {

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

    public func removeValueForKey<T>(_ key: PersistenceKey<T?>) {
        userDefaults.removeObject(forKey: key.key)
    }
}
