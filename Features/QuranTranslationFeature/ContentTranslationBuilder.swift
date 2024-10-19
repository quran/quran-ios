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
import SwiftUI
import TranslationService

public struct ContentTranslationBuilder {
    private let container: AppDependencies
    private let highlightsService: QuranHighlightsService

    public init(container: AppDependencies, highlightsService: QuranHighlightsService) {
        self.container = container
        self.highlightsService = highlightsService
    }

    @MainActor
    public func build(at page: Page) -> some View {
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
        viewModel.verses = page.verses
        return ContentTranslationView(viewModel: viewModel)
    }
}
