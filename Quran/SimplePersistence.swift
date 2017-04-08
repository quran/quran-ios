//
//  SimplePersistence.swift
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

class PersistenceKeyBase {
    static let lastSelectedQariId = PersistenceKey<Int>(key: "LastSelectedQariId", defaultValue: -1)
    static let lastViewedPage = PersistenceKey<Int?>(key: "LastViewedPage", defaultValue: nil)
    static let showQuranTranslationView = PersistenceKey<Bool>(key: "showQuranTranslationView", defaultValue: false)
    static let selectedTranslations = PersistenceKey<[Int]>(key: "selectedTranslations", defaultValue: [])
}

#if DEBUG
private struct Statics {
    static var registeredKeys = Set<String>()
}
#endif

final class PersistenceKey<Type>: PersistenceKeyBase {
    let key: String
    let defaultValue: Type

    fileprivate init(key: String, defaultValue: Type) {
        self.key = key
        self.defaultValue = defaultValue

        #if DEBUG
            if Statics.registeredKeys.contains(key) {
                fatalError("PersistenceKey '\(key)' is registered multiple times")
            }
            Statics.registeredKeys.insert(key)
        #endif
    }
}

protocol SimplePersistence {

    func valueForKey<T>(_ key: PersistenceKey<T>) -> T
    func setValue<T>(_ value: T?, forKey key: PersistenceKey<T>)
    func removeValueForKey<T>(_ key: PersistenceKey<T?>)
}
