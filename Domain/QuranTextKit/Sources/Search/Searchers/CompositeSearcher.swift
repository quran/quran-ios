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

public struct CompositeSearcher {
    // MARK: Lifecycle

    init(
        quranVerseTextPersistence: VerseTextPersistence,
        localTranslationRetriever: LocalTranslationsRetriever,
        versePersistenceBuilder: @escaping (Translation) -> TranslationVerseTextPersistence
    ) {
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
        self.init(
            quranVerseTextPersistence: persistence,
            localTranslationRetriever: localTranslationRetriever,
            versePersistenceBuilder: { translation in
                GRDBTranslationVerseTextPersistence(fileURL: translation.localPath.url)
            }
        )
    }

    // MARK: Public

    public func autocomplete(term: String, quran: Quran) async -> [String] {
        guard let term = SearchTerm(term) else {
            return []
        }
        logger.info("Autocompleting term: \(term.compactQuery)")

        let autocompletions = await simpleSearchers.asyncMap { searcher in
            try? await searcher.autocomplete(term: term, quran: quran)
        }
        var results = autocompletions.compactMap { $0 }.flatMap { $0 }

        if shouldPerformTranslationSearch(simpleSearchResults: results, term: term.compactQuery) {
            results += (try? await translationsSearcher.autocomplete(term: term, quran: quran)) ?? []
        }
        if !results.contains(term.compactQuery) {
            results.insert(term.compactQuery, at: 0)
        }
        return results.orderedUnique()
    }

    public func search(for term: String, quran: Quran) async throws -> [SearchResults] {
        guard let term = SearchTerm(term) else {
            return []
        }
        logger.info("Search for: \(term.compactQuery)")

        let searchResults = try await simpleSearchers.asyncMap { searcher in
            try await searcher.search(for: term, quran: quran)
        }
        var results = searchResults
            .flatMap { $0 }
            .filter { !$0.items.isEmpty } // Remove empty search results
        if shouldPerformTranslationSearch(simpleSearchResults: results, term: term.compactQuery) {
            results += try await translationsSearcher.search(for: term, quran: quran)
                .filter { !$0.items.isEmpty } // Remove empty search results
        }

        return groupedResults(results)
    }

    // MARK: Private

    private let simpleSearchers: [Searcher]
    private let translationsSearcher: Searcher

    private func groupedResults(_ results: [SearchResults]) -> [SearchResults] {
        var resultsPerSource: [SearchResults.Source: [SearchResult]] = [:]
        for result in results {
            var list = resultsPerSource[result.source] ?? []
            list.append(contentsOf: result.items)
            resultsPerSource[result.source] = list
        }
        return resultsPerSource
            .map { source, items in SearchResults(source: source, items: items) }
            .sorted { $0.source < $1.source }
    }

    private func shouldPerformTranslationSearch(simpleSearchResults: [some Any], term: String) -> Bool {
        simpleSearchResults.isEmpty || (!term.containsArabic() && !term.containsOnlyNumbers())
    }
}
