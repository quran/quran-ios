//
//  TranslationVerseBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AppDependencies
import Caching
import Foundation
import MoreMenuFeature
import NoorUI
import PromiseKit
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

    public func build(startingVerse: AyahNumber, quranUITraits: QuranUITraits, actions: TranslationVerseActions) -> UIViewController {
        let dataService = QuranTextDataService(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        let viewModel = TranslationVerseViewModel(startingVerse: startingVerse, dataService: dataService, actions: actions)
        let viewController = TranslationVerseViewController(
            viewModel: viewModel,
            quranUITraits: quranUITraits,
            moreMenuBuilder: MoreMenuBuilder(),
            translationsSelectionBuilder: TranslationsListBuilder(container: container)
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }

    // MARK: Private

    private let container: AppDependencies
}
