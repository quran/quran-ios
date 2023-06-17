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

import Foundation

public class SearchRecentsService {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func getPopularTerms() -> [String] {
        let recentsCount = preferences.recentSearchItems.count
        guard recentsCount < removePopularWhenRecentsCount else {
            return []
        }
        return Array(popularTerms.dropLast(recentsCount))
    }

    public func getRecents() -> [String] {
        preferences.recentSearchItems
    }

    public func addToRecents(_ term: String) {
        var recents = preferences.recentSearchItems
        if let index = recents.firstIndex(of: term) {
            recents.remove(at: index)
        }
        recents.insert(term, at: 0)
        if recents.count > maxCount {
            recents = recents.dropLast(recents.count - maxCount)
        }
        preferences.recentSearchItems = recents
    }

    // MARK: Private

    private let maxCount: Int = 5
    private let removePopularWhenRecentsCount = 3

    private let preferences = RecentSearchPreferences.shared

    private let popularTerms: [String] = ["الرحمن الرحيم", "الحي القيوم", "يس", "تبارك"]
}
