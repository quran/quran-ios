//
//  Searcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import QuranKit
import QuranText

public protocol Searcher {
    func autocomplete(term: String, quran: Quran) async throws -> [String]
    func search(for term: String, quran: Quran) async throws -> [SearchResults]
}
