//
//  SearchBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import AppDependencies
import FeaturesSupport
import QuranTextKit
import TranslationService
import UIKit

@MainActor
public struct SearchBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        let viewModel = SearchViewModel(
            analytics: container.analytics,
            searchService: CompositeSearcher(
                databasesURL: container.databasesURL,
                quranFileURL: container.quranUthmaniV2Database
            ),
            navigateTo: { [weak listener] verse in
                listener?.navigateTo(page: verse.page, lastPage: nil, highlightingSearchAyah: verse)
            }
        )
        let viewController = SearchViewController(viewModel: viewModel)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
