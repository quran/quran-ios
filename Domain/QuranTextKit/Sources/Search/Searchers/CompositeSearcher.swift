//
//  CompositeSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-17.
//

import Foundation
import QuranKit
import QuranText
import TranslationService
import VerseTextPersistence
import VLogging

public struct CompositeSearcher: Searcher {
    private let simpleSearchers: [Searcher]
    private let translationsSearcher: Searcher

    init(quranVerseTextPersistence: VerseTextPersistence,
         localTranslationRetriever: LocalTranslationsRetriever,
         versePersistenceBuilder: @escaping (Translation) -> TranslationVerseTextPersistence)
    {
        let numberSearcher = NumberSearcher(quranVerseTextPersistence: quranVerseTextPersistence)
        let quranSearcher = PersistenceSearcher(versePersistence: quranVerseTextPersistence, source: .quran)
        let suraSearcher = SuraSearcher()
        let translationSearcher = TranslationSearcher(
            localTranslationRetriever: localTranslationRetriever,
            versePersistenceBuilder: versePersistenceBuilder
        )

        let simpleSearchers: [Searcher] = [numberSearcher, suraSearcher, quranSearcher]
        self.simpleSearchers = simpleSearchers
        translationsSearcher = translationSearcher
    }

    public init(databasesURL: URL, quranFileURL: URL) {
        let persistence = GRDBQuranVerseTextPersistence(fileURL: quranFileURL)
        let localTranslationRetriever = TranslationService.LocalTranslationsRetriever(databasesURL: databasesURL)
        self.init(quranVerseTextPersistence: persistence,
                  localTranslationRetriever: localTranslationRetriever,
                  versePersistenceBuilder: { translation in
                      GRDBTranslationVerseTextPersistence(fileURL: translation.localURL)
                  })
    }

    public func autocomplete(term: String, quran: Quran) async throws -> [SearchAutocompletion] {
        logger.info("Autocompleting term: \(term)")

        let autocompletions = try await simpleSearchers.asyncMap { searcher in
            try await searcher.autocomplete(term: term, quran: quran)
        }
        var results = autocompletions.flatMap { $0 }

        if results.isEmpty {
            results = try await translationsSearcher.autocomplete(term: term, quran: quran)
        }
        let termResult = SearchAutocompletion(text: term, term: term)
        results.insert(termResult, at: 0)
        return results.orderedUnique()
    }

    public func search(for term: String, quran: Quran) async throws -> [SearchResults] {
        logger.info("Search for: \(term)")
        let searchResults = try await simpleSearchers.asyncMap { searcher in
            try await searcher.search(for: term, quran: quran)
        }
        var results = searchResults.flatMap { $0 }
        results = results.filter { !$0.items.isEmpty } // Remove empty search results
        if results.isEmpty {
            results = try await translationsSearcher.search(for: term, quran: quran)
        }
        return results.filter { !$0.items.isEmpty } // Remove empty search results
    }
}
