//
//  TranslationSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-17.
//

import Foundation
import PromiseKit
import QuranKit
import TranslationService

struct TranslationSearcher: AsyncSearcher {
    let localTranslationRetriever: LocalTranslationsRetriever
    let versePersistenceBuilder: (Translation, Quran) -> SearchableTextPersistence
    let quran: Quran

    private func getLocalTranslations() -> Promise<[Translation]> {
        localTranslationRetriever
            .getLocalTranslations()
            .map { $0.filter(\.isDownloaded) }
    }

    func autocomplete(term: String) -> Promise<[SearchAutocompletion]> {
        getLocalTranslations()
            .map { translations -> [SearchAutocompletion] in
                for translation in translations {
                    let persistence = self.versePersistenceBuilder(translation, quran)
                    let persistenceSearcher = PersistenceSearcher(versePersistence: persistence, source: .translation(translation))
                    let results = try persistenceSearcher.autocomplete(term: term)
                    if !results.isEmpty {
                        return results
                    }
                }
                return []
            }
    }

    func search(for term: String) -> Promise<[SearchResults]> {
        getLocalTranslations()
            .map { translations -> [SearchResults] in
                let results = try translations.map { translation -> [SearchResults] in
                    let persistence = self.versePersistenceBuilder(translation, quran)
                    let persistenceSearcher = PersistenceSearcher(versePersistence: persistence, source: .translation(translation))
                    let results = try persistenceSearcher.search(for: term)
                    return results
                }
                return results.flatMap { $0 }
            }
    }
}
