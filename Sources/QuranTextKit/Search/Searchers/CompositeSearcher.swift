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

    init(quran: Quran,
         quranVerseTextPersistence: VerseTextPersistence,
         localTranslationRetriever: LocalTranslationsRetriever,
         versePersistenceBuilder: @escaping (Translation, Quran) -> VerseTextPersistence)
    {
        let numberSearcher = NumberSearcher(quran: quran, quranVerseTextPersistence: quranVerseTextPersistence)
        let quranSearcher = PersistenceSearcher(versePersistence: quranVerseTextPersistence, source: .quran)
        let suraSearcher = SuraSearcher(quran: quran)
        let translationSearcher = TranslationSearcher(
            localTranslationRetriever: localTranslationRetriever,
            versePersistenceBuilder: versePersistenceBuilder,
            quran: quran
        )

        let simpleSearchers: [Searcher] = [numberSearcher, suraSearcher, quranSearcher]
        self.simpleSearchers = simpleSearchers
        translationsSearcher = translationSearcher
    }

    public init(databasesPath: String, quranFileURL: URL) {
        let quran = Quran.madani
        let persistence = SQLiteQuranVerseTextPersistence(quran: quran, fileURL: quranFileURL)
        let localTranslationRetriever = TranslationService.LocalTranslationsRetriever(databasesPath: databasesPath)
        self.init(quran: quran,
                  quranVerseTextPersistence: persistence,
                  localTranslationRetriever: localTranslationRetriever,
                  versePersistenceBuilder: { translation, quran in
                      SQLiteTranslationVerseTextPersistence(fileURL: translation.localURL, quran: quran)
                  })
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
