//
//  SimplePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class PersistenceKeyBase {
    static let lastSelectedQariId = PersistenceKey<Int>(key: "LastSelectedQariId", defaultValue: -1)
    static let lastViewedPage = PersistenceKey<Int?>(key: "LastViewedPage", defaultValue: nil)
    static let showQuranTranslationView = PersistenceKey<Bool>(key: "showQuranTranslationView", defaultValue: false)
    static let selectedTranslations = PersistenceKey<[Int]>(key: "showQuranTranslationView", defaultValue: [])
}

final class PersistenceKey<Type>: PersistenceKeyBase {
    let key: String
    let defaultValue: Type

    fileprivate init(key: String, defaultValue: Type) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

protocol SimplePersistence {

    func valueForKey<T>(_ key: PersistenceKey<T>) -> T
    func setValue<T>(_ value: T?, forKey key: PersistenceKey<T>)
    func removeValueForKey<T>(_ key: PersistenceKey<T?>)
}
