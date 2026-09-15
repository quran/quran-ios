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
    private let overlayService: VerseOverlayService

    public init(container: AppDependencies, overlayService: VerseOverlayService) {
        self.container = container
        self.overlayService = overlayService
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
            overlayService: overlayService
        )
        viewModel.verses = page.verses
        return ContentTranslationView(viewModel: viewModel)
    }
}
