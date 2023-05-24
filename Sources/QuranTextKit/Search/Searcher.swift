//
//  Searcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import PromiseKit
import QuranKit

public protocol Searcher {
    func autocomplete(term: String, quran: Quran) async throws -> [SearchAutocompletion]
    func search(for term: String, quran: Quran) async throws -> [SearchResults]
}
