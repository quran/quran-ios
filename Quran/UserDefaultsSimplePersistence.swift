//
//  UserDefaultsSimplePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct UserDefaultsSimplePersistence: SimplePersistence {

    let userDefaults: UserDefaults

    func valueForKey<T>(_ key: PersistenceKey<T>) -> T {
        let value = userDefaults.object(forKey: key.key)
        return (value as? T) ?? key.defaultValue
    }

    func setValue<T>(_ value: T?, forKey key: PersistenceKey<T>) {

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
        } else if let value = value as? Foundation.URL {
            userDefaults.set(value, forKey: key.key)
        } else if let value = value as? Data {
            userDefaults.set(value, forKey: key.key)
        } else {
            userDefaults.set(value, forKey: key.key)
        }
    }

    func removeValueForKey<T>(_ key: PersistenceKey<T?>) {
        userDefaults.removeObject(forKey: key.key)
    }
}
