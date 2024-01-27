//
//  ContentTranslationBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/30/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import QuranKit
import QuranPagesFeature
import QuranTextKit
import TranslationService

public struct ContentTranslationBuilder: PageViewBuilder {
    private let container: AppDependencies
    private let highlightsService: QuranHighlightsService

    public init(container: AppDependencies, highlightsService: QuranHighlightsService) {
        self.container = container
        self.highlightsService = highlightsService
    }

    public func build(at page: Page) -> PageView {
        let dataService = QuranTextDataService(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )

        let localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: container.databasesURL)
        let viewModel = ContentTranslationViewModel(
            localTranslationsRetriever: localTranslationsRetriever,
            dataService: dataService,
            highlightsService: highlightsService
        )
        return ContentTranslationViewController(page: page, viewModel: viewModel)
    }
}
