//
//  ContentTranslationBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/30/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import Caching
import Foundation
import QuranKit
import QuranPagesFeature
import QuranTextKit
import Utilities

public struct ContentTranslationBuilder: PageDataSourceBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(actions: PageDataSourceActions, pages: [Page]) -> PageDataSource {
        let dataService = createElementLoader(pages: pages)
        return PageDataSource(actions: actions) { page in
            ContentTranslationViewController(dataService: dataService, page: page)
        }
    }

    // MARK: Private

    private let container: AppDependencies

    private func createElementLoader(pages: [Page]) -> PagesCacheableService<Page, TranslatedPage> {
        let cache = Cache<Page, TranslatedPage>()
        cache.countLimit = 5

        let translationService = QuranTextDataService(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        let operation = { @Sendable (page: Page) in
            let texts = try await translationService.textForVerses(page.verses)
            let translations = Translations(texts.translations)
            let translatedVerses = zip(page.verses, texts.verses).map { verse, text in
                TranslatedVerse(verse: verse, text: text, translations: translations)
            }
            return TranslatedPage(translatedVerses: translatedVerses)
        }

        return PagesCacheableService(
            cache: cache,
            previousPagesCount: 1,
            nextPagesCount: 2,
            pages: pages,
            operation: operation
        )
    }
}
