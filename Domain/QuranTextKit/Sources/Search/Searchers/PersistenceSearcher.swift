//
//  PersistenceSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import Foundation
import QuranKit
import QuranText
import VerseTextPersistence

struct PersistenceSearcher: Searcher {
    let versePersistence: SearchableTextPersistence
    let source: SearchResults.Source

    func autocomplete(term: SearchTerm, quran: Quran) async throws -> [String] {
        let matches = try await versePersistence.autocomplete(term: term.persistenceQuery)
        return term.buildAutocompletions(searchResults: matches)
    }

    func search(for term: SearchTerm, quran: Quran) async throws -> [SearchResults] {
        // Replace certainCharacters with similar other
        let persistenceSearchTerm = term.persistenceQueryReplacingArabicSimilarityCharactersWithUnderscore()
        if persistenceSearchTerm.isEmpty {
            return []
        }
        let matches = try await versePersistence.search(for: persistenceSearchTerm, quran: quran)

        // Use the passed in term to match the original letters not underscoes.
        let items = term.buildSearchResults(verses: matches)
        return [SearchResults(source: source, items: items)]
    }
}
