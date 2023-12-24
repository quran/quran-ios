//
//  TranslationVerseBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import Caching
import Foundation
import MoreMenuFeature
import QuranAnnotations
import QuranKit
import QuranTextKit
import TranslationsFeature
import UIKit

@MainActor
public struct TranslationVerseBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(startingVerse: AyahNumber, actions: TranslationVerseActions) -> UIViewController {
        let dataService = QuranTextDataService(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        let viewModel = TranslationVerseViewModel(startingVerse: startingVerse, dataService: dataService, actions: actions)
        let viewController = TranslationVerseViewController(
            viewModel: viewModel,
            moreMenuBuilder: MoreMenuBuilder(),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            // Pass a new highlights service that will always be empty
            highlightsService: QuranHighlightsService()
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }

    // MARK: Private

    private let container: AppDependencies
}
