//
//  ContentTranslationBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/30/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import Caching
import Foundation
import QuranKit
import QuranPagesFeature
import QuranTextKit
import ReadingService
import UIKit
import Utilities

public struct ContentTranslationBuilder: PageViewBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies, highlightsService: QuranHighlightsService) {
        self.container = container
        self.highlightsService = highlightsService

        let reading = ReadingPreferences.shared.reading
        let pages = reading.quran.pages
        (dataService, selectedTranslationsMonitor) = Self.createElementLoader(pages: pages, container: container)
    }

    // MARK: Public

    public func build(at page: Page) -> PageView {
        ContentTranslationViewController(dataService: dataService, page: page, highlightsService: highlightsService)
    }

    // MARK: Private

    private let container: AppDependencies
    private let highlightsService: QuranHighlightsService
    private let dataService: PagesCacheableService<Page, TranslatedPage>
    private let selectedTranslationsMonitor: SelectedTranslationsMonitor

    private static func createElementLoader(
        pages: [Page],
        container: AppDependencies
    ) -> (PagesCacheableService<Page, TranslatedPage>, SelectedTranslationsMonitor) {
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

        let service = PagesCacheableService(
            cache: cache,
            previousPagesCount: 1,
            nextPagesCount: 2,
            pages: pages,
            operation: operation
        )

        let monitor = SelectedTranslationsMonitor(cache: cache)
        return (service, monitor)
    }
}
