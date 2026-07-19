//
//  TranslationVerseBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AppDependencies
import MoreMenuFeature
import QuranKit
import QuranTextKit
import TranslationService
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
        let localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: container.databasesURL)
        let viewModel = TranslationVerseViewModel(startingVerse: startingVerse, localTranslationsRetriever: localTranslationsRetriever, dataService: dataService, actions: actions)
        let viewController = TranslationVerseViewController(
            viewModel: viewModel,
            moreMenuBuilder: MoreMenuBuilder(),
            translationsSelectionBuilder: TranslationsListBuilder(container: container)
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }

    // MARK: Private

    private let container: AppDependencies
}
