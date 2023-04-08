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
    let versePersistenceBuilder: (Translation) -> SearchableTextPersistence

    private func getLocalTranslations() -> Promise<[Translation]> {
        localTranslationRetriever
            .getLocalTranslations()
            .map { $0.filter(\.isDownloaded) }
    }

    func autocomplete(term: String, quran: Quran) -> Promise<[SearchAutocompletion]> {
        getLocalTranslations()
            .map { translations -> [SearchAutocompletion] in
                for translation in translations {
                    let persistence = self.versePersistenceBuilder(translation)
                    let persistenceSearcher = PersistenceSearcher(versePersistence: persistence, source: .translation(translation))
                    let results = try persistenceSearcher.autocomplete(term: term, quran: quran)
                    if !results.isEmpty {
                        return results
                    }
                }
                return []
            }
    }

    func search(for term: String, quran: Quran) -> Promise<[SearchResults]> {
        getLocalTranslations()
            .map { translations -> [SearchResults] in
                let results = try translations.map { translation -> [SearchResults] in
                    let persistence = self.versePersistenceBuilder(translation)
                    let persistenceSearcher = PersistenceSearcher(versePersistence: persistence, source: .translation(translation))
                    let results = try persistenceSearcher.search(for: term, quran: quran)
                    return results
                }
                return results.flatMap { $0 }
            }
    }
}
