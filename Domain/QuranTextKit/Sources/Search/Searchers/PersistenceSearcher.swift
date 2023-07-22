//
//  PersistenceSearcher..swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import Foundation
import QuranKit
import QuranText
import VerseTextPersistence

struct PersistenceSearcher: Searcher {
    // MARK: Internal

    let versePersistence: SearchableTextPersistence
    let source: SearchResults.Source

    func autocomplete(term: String, quran: Quran) async throws -> [String] {
        let processedTerm = termProcessor.prepareSearchTermForAutocompletion(term)
        if processedTerm.isEmpty {
            return []
        }
        let matches = try await versePersistence.autocomplete(term: processedTerm)
        return resultsProcessor.buildAutocompletions(searchResults: matches, term: processedTerm)
    }

    func search(for term: String, quran: Quran) async throws -> [SearchResults] {
        let processedTerm = termProcessor.prepareSearchTermForSearching(term)
        if processedTerm.searchTerm.isEmpty {
            return []
        }
        let matches = try await versePersistence.search(for: processedTerm.searchTerm, quran: quran)
        let items = resultsProcessor.buildSearchResults(searchRegex: processedTerm.pattern, verses: matches)
        return [SearchResults(source: source, items: items)]
    }

    // MARK: Private

    private let termProcessor = SearchTermProcessor()
    private let resultsProcessor = SearchResultsProcessor()
}
