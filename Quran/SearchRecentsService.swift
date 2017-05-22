//
//  SearchRecentsService.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/17/17.
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

extension PersistenceKeyBase {
    fileprivate static let searchRecentItems = PersistenceKey<NSOrderedSet>(key: "com.quran.searchRecentItems", defaultValue: [])
}

protocol SearchRecentsService {
    func getPopularTerms() -> [String]
    func getRecents() -> [String]
    func addToRecents(_ term: String)
}

class DefaultSearchRecentsService: SearchRecentsService {
    private let maxCount: Int = 5
    private let removePopularWhenRecentsCount = 3

    private let persistence: SimplePersistence

    private let popularTerms: [String] = ["الرحمن الرحيم", "الحي القيوم", "يس", "تبارك"]

    init(persistence: SimplePersistence) {
        self.persistence = persistence
    }

    func getPopularTerms() -> [String] {
        let recentsCount = persistence.serializedValueForKey(.searchRecentItems).count
        guard recentsCount < removePopularWhenRecentsCount else {
            return []
        }
        return Array(popularTerms.dropLast(recentsCount))
    }

    func getRecents() -> [String] {
        let recents = persistence.serializedValueForKey(.searchRecentItems)
        return recents.map { $0 as! String } // swiftlint:disable:this force_cast
    }

    func addToRecents(_ term: String) {
        let recents = persistence.serializedValueForKey(.searchRecentItems)
        let mutable = NSMutableOrderedSet(orderedSet: recents, copyItems: false)
        mutable.remove(term)
        mutable.insert(term, at: 0)
        if mutable.count > maxCount {
            mutable.removeObjects(in: NSRange(location: maxCount, length: mutable.count - maxCount))
        }
        persistence.setSerializedValue(NSOrderedSet(orderedSet: mutable), forKey: .searchRecentItems)
    }
}
