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

    init(
        versePersistence: any VerseTextPersistence,
        source: SearchResults.Source
    ) where Text == QuranText {
        self.source = source
        autocompletePersistence = { term in
            try await versePersistence.autocomplete(term: term)
        }
        searchPersistence = { term, quran in
            try await versePersistence.search(for: term, quran: quran)
        }
    }

    init(
        versePersistence: any TranslationVerseTextPersistence,
        source: SearchResults.Source
    ) where Text == String {
        self.source = source
        autocompletePersistence = { term in
            try await versePersistence.autocomplete(term: term)
        }
        searchPersistence = { term, quran in
            try await versePersistence.search(for: term, quran: quran)
        }
    }

    // MARK: Internal

    func autocomplete(term: SearchTerm, quran: Quran) async throws -> [SearchText] {
        let matches = try await autocompletePersistence(term.persistenceQuery)
        return term.buildAutocompletions(searchResults: matches)
    }

    func search(for term: SearchTerm, quran: Quran) async throws -> [SearchResults] {
        // Replace certainCharacters with similar other
        let persistenceSearchTerm = term.persistenceQueryReplacingArabicSimilarityCharactersWithUnderscore()
        if persistenceSearchTerm.isEmpty {
            return []
        }
        let matches = try await searchPersistence(persistenceSearchTerm, quran)

        // Use the passed in term to match the original letters not underscoes.
        let items = term.buildSearchResults(verses: matches)
        return [SearchResults(source: source, items: items)]
    }

    // MARK: Private

    private let source: SearchResults.Source
    private let autocompletePersistence: (String) async throws -> [Text]
    private let searchPersistence: (String, Quran) async throws -> [(verse: AyahNumber, text: Text)]
}
