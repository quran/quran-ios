//
//  UserDefaultsSimplePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct UserDefaultsSimplePersistence: SimplePersistence {

    let userDefaults: NSUserDefaults

    func valueForKey<T>(key: PersistenceKey<T>) -> T {
        let value = userDefaults.objectForKey(key.key)
        return (value as? T) ?? key.defaultValue
    }

    func setValue<T>(value: T?, forKey key: PersistenceKey<T>) {

        guard let value = value else {
            userDefaults.removeObjectForKey(key.key)
            return
        }

        if let value = value as? Int {
            userDefaults.setInteger(value, forKey: key.key)
        } else if let value = value as? Float {
            userDefaults.setFloat(value, forKey: key.key)
        } else if let value = value as? Double {
            userDefaults.setDouble(value, forKey: key.key)
        } else if let value = value as? Bool {
            userDefaults.setBool(value, forKey: key.key)
        } else if let value = value as? NSURL {
            userDefaults.setURL(value, forKey: key.key)
        } else if let value = value as? AnyObject {
            userDefaults.setObject(value, forKey: key.key)
        } else {
            fatalError("Unsupported value type")
        }
    }

    func removeValueForKey<T>(key: PersistenceKey<T?>) {
        userDefaults.removeObjectForKey(key.key)
    }
}
