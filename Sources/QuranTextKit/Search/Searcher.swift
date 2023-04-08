//
//  Searcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import PromiseKit
import QuranKit

protocol Searcher {
    func autocomplete(term: String, quran: Quran) throws -> [SearchAutocompletion]
    func search(for term: String, quran: Quran) throws -> [SearchResults]
}

public protocol AsyncSearcher {
    func autocomplete(term: String, quran: Quran) -> Promise<[SearchAutocompletion]>
    func search(for term: String, quran: Quran) -> Promise<[SearchResults]>
}
