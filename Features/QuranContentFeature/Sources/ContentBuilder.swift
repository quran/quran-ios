//
//  ContentBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import QuranImageFeature
import QuranTranslationFeature
import ReadingService

@MainActor
public struct ContentBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies, overlayService: VerseOverlayService) {
        self.container = container
        self.overlayService = overlayService
    }

    // MARK: Public

    public func build(withListener listener: ContentListener, input: QuranInput) -> (ContentViewController, ContentViewModel) {
        let quran = ReadingPreferences.shared.reading.quran
        let lastPageUpdater = LastPageUpdater(service: container.lastPageService())
        let interactorDeps = ContentViewModel.Deps(
            analytics: container.analytics,
            lastPageUpdater: lastPageUpdater,
            quran: quran,
            overlayService: overlayService,
            imageDataSourceBuilder: ContentImageBuilder(container: container, overlayService: overlayService),
            translationDataSourceBuilder: ContentTranslationBuilder(container: container, overlayService: overlayService)
        )
        let viewModel = ContentViewModel(deps: interactorDeps, input: input)

        let viewController = ContentViewController(viewModel: viewModel)

        viewModel.listener = listener
        return (viewController, viewModel)
    }

    // MARK: Private

    private let container: AppDependencies
    private let overlayService: VerseOverlayService
}
