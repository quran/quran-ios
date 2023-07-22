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
import Preferences
import Utilities

public class SearchRecentsService {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = SearchRecentsService()

    public let popularTerms: [String] = [
        "الرحمن",
        "الحي القيوم",
        "يس",
        "7",
        "5:88",
        "تبارك",
        "عم",
        "أعوذ",
    ]

    @TransformedPreference(searchRecentItems, transformer: searchRecentItemsTransfomer)
    public var recentSearchItems: [String]

    public func addToRecents(_ term: String) {
        var recents = recentSearchItems
        if let index = recents.firstIndex(of: term) {
            recents.remove(at: index)
        }
        recents.insert(term, at: 0)
        if recents.count > maxCount {
            recents = recents.dropLast(recents.count - maxCount)
        }
        recentSearchItems = recents
    }

    // MARK: Private

    private static let searchRecentItems = PreferenceKey<[String]>(key: "com.quran.searchRecentItems", defaultValue: [])
    private static let searchRecentItemsTransfomer = PreferenceTransformer<[String], [String]>(
        rawToValue: { $0.orderedUnique() },
        valueToRaw: { $0 }
    )

    private let maxCount: Int = 5
}
