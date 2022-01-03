//
//  CompositeSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-17.
//

import Foundation
import PromiseKit
import QuranKit
import TranslationService
import VLogging

public struct CompositeSearcher: AsyncSearcher {
    private let simpleSearchers: [Searcher]
    private let translationsSearcher: AsyncSearcher

    init(simpleSearchers: [Searcher], translationsSearcher: AsyncSearcher) {
        self.simpleSearchers = simpleSearchers
        self.translationsSearcher = translationsSearcher
    }

    public init(databasesPath: String, quranFileURL: URL) {
        let persistence = SQLiteQuranVerseTextPersistence(quran: Quran.madani, fileURL: quranFileURL)

        let numberSearcher = NumberSearcher(quran: Quran.madani, quranVerseTextPersistence: persistence)
        let quranSearcher = PersistenceSearcher(versePersistence: persistence, source: .quran)
        let suraSearcher = SuraSearcher(quran: Quran.madani)
        let translationSearcher = TranslationSearcher(
            localTranslationRetriever: TranslationService.LocalTranslationsRetriever(databasesPath: databasesPath),
            versePersistenceBuilder: { translation, quran in
                SQLiteTranslationVerseTextPersistence(fileURL: translation.localURL, quran: quran)
            },
            quran: Quran.madani
        )

        let simpleSearchers: [Searcher] = [numberSearcher, suraSearcher, quranSearcher]
        self.init(simpleSearchers: simpleSearchers, translationsSearcher: translationSearcher)
    }

    public func autocomplete(term: String) -> Promise<[SearchAutocompletion]> {
        logger.info("Autocompleting term: \(term)")
        return DispatchQueue.global()
            .async(.promise) {
                try self.simpleSearchers.flatMap { try $0.autocomplete(term: term) }
            }
            .then { results -> Promise<[SearchAutocompletion]> in
                if !results.isEmpty {
                    return .value(results)
                }
                return self.translationsSearcher.autocomplete(term: term)
            }
            .map { [SearchAutocompletion(text: term, highlightedRange: term.startIndex ..< term.endIndex)] + $0 }
            .map { $0.orderedUnique() }
    }

    public func search(for term: String) -> Promise<[SearchResults]> {
        logger.info("Search for: \(term)")
        return DispatchQueue.global()
            .async(.promise) {
                try self.simpleSearchers.flatMap { try $0.search(for: term) }
            }
            .map {
                $0.filter { !$0.items.isEmpty }
            }
            .then { results -> Promise<[SearchResults]> in
                if !results.isEmpty {
                    return .value(results)
                }
                return self.translationsSearcher.search(for: term)
            }
            .map {
                $0.filter { !$0.items.isEmpty }
            }
    }
}
