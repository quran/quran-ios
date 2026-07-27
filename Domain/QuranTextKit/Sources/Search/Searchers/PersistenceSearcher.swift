//
//  PersistenceSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import QuranKit
import QuranText
import VerseTextPersistence

protocol PersistenceSearchText {
    var searchableText: String { get }

    static func makeSearchText(_ text: String) -> SearchText
}

extension String: PersistenceSearchText {
    var searchableText: String { self }

    static func makeSearchText(_ text: String) -> SearchText {
        .plain(text)
    }
}

extension QuranText: PersistenceSearchText {
    var searchableText: String { text }

    static func makeSearchText(_ text: String) -> SearchText {
        .quran(QuranText(text))
    }
}

struct PersistenceSearcher<Text: PersistenceSearchText>: Searcher {
    // MARK: Lifecycle

    init<Persistence: SearchableTextPersistence>(
        versePersistence: Persistence,
        source: SearchResults.Source
    ) where Persistence.Text == Text {
        self.versePersistence = versePersistence
        self.source = source
    }

    // MARK: Internal

    func autocomplete(term: SearchTerm, quran: Quran) async throws -> [SearchText] {
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

    // MARK: Private

    private let versePersistence: any SearchableTextPersistence<Text>
    private let source: SearchResults.Source
}
