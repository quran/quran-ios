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

protocol SearchRecentsService {
    func getPopularTerms() -> [String]
    func getRecents() -> [String]
    func addToRecents(_ term: String)
}

class DefaultSearchRecentsService: SearchRecentsService {
    private let maxCount: Int = 5
    private let removePopularWhenRecentsCount = 3

    private let popularTerms: [String] = ["Popular 1", "Popular 2", "Way popular", "Way popular 2"]
    private var recents: NSMutableOrderedSet = [] // ["A", "b", "d"]

    func getPopularTerms() -> [String] {
        guard recents.count < removePopularWhenRecentsCount else {
            return []
        }
        return Array(popularTerms.dropLast(recents.count))
    }

    func getRecents() -> [String] {
        return recents.map { $0 as! String } // swiftlint:disable:this force_cast
    }

    func addToRecents(_ term: String) {
        recents.remove(term)
        recents.insert(term, at: 0)
        if recents.count > maxCount {
            recents.removeObjects(in: NSRange(location: maxCount, length: recents.count - maxCount))
        }
    }
}
