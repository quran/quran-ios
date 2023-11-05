//
//  Searcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import QuranKit
import QuranText

protocol Searcher {
    func autocomplete(term: SearchTerm, quran: Quran) async throws -> [String]
    func search(for term: SearchTerm, quran: Quran) async throws -> [SearchResults]
}
