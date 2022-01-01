//
//  Searcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import PromiseKit

protocol Searcher {
    func autocomplete(term: String) throws -> [SearchAutocompletion]
    func search(for term: String) throws -> [SearchResults]
}

public protocol AsyncSearcher {
    func autocomplete(term: String) -> Promise<[SearchAutocompletion]>
    func search(for term: String) -> Promise<[SearchResults]>
}
