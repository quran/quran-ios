//
//  SimplePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class PersistenceKeyBase {
    static let LastViewedPage = PersistenceKey<Int?>(key: "LastViewedPage", defaultValue: nil)
    static let LastSelectedQariId = PersistenceKey<Int>(key: "LastSelectedQariId", defaultValue: -1)
}

final class PersistenceKey<Type>: PersistenceKeyBase {
    let key: String
    let defaultValue: Type

    init(key: String, defaultValue: Type) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

protocol SimplePersistence {

    func valueForKey<T>(key: PersistenceKey<T>) -> T
    func setValue<T>(value: T?, forKey key: PersistenceKey<T>)
    func removeValueForKey<T>(key: PersistenceKey<T?>)
}
