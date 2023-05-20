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

    public init(databasesPath: String, quranFileURL: URL) {
        let persistence = SQLiteQuranVerseTextPersistence(fileURL: quranFileURL)
        let localTranslationRetriever = TranslationService.LocalTranslationsRetriever(databasesPath: databasesPath)
        self.init(quranVerseTextPersistence: persistence,
                  localTranslationRetriever: localTranslationRetriever,
                  versePersistenceBuilder: { translation in
                      SQLiteTranslationVerseTextPersistence(fileURL: translation.localURL)
                  })
    }

    public func autocomplete(term: String, quran: Quran) -> Promise<[SearchAutocompletion]> {
        logger.info("Autocompleting term: \(term)")
        return DispatchQueue.global()
            .async(.promise) {
                try simpleSearchers.flatMap { try $0.autocomplete(term: term, quran: quran) }
            }
            .then { (results: [SearchAutocompletion]) -> Promise<[SearchAutocompletion]> in
                if !results.isEmpty {
                    return .value(results)
                }
                return translationsSearcher.autocomplete(term: term, quran: quran)
            }
            .map { [SearchAutocompletion(text: term, term: term)] + $0 }
            .map { $0.orderedUnique() }
    }

    public func search(for term: String, quran: Quran) -> Promise<[SearchResults]> {
        logger.info("Search for: \(term)")
        return DispatchQueue.global()
            .async(.promise) {
                try simpleSearchers.flatMap { try $0.search(for: term, quran: quran) }
            }
            .map {
                $0.filter { !$0.items.isEmpty }
            }
            .then { results -> Promise<[SearchResults]> in
                if !results.isEmpty {
                    return .value(results)
                }
                return translationsSearcher.search(for: term, quran: quran)
            }
            .map {
                $0.filter { !$0.items.isEmpty }
            }
    }
}
