//
//  HomeBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import FeaturesSupport
import QuranTextKit
import ReadingSelectorFeature
import UIKit

@MainActor
public struct HomeBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        let lastPageService = LastPageService(persistence: container.lastPagePersistence)
        let textRetriever = QuranTextDataService(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )

        #if QURAN_SYNC
            let viewModel = HomeViewModel(
                lastPageService: lastPageService,
                textRetriever: textRetriever,
                navigateToPage: { [weak listener] lastPage in
                    listener?.navigateTo(page: lastPage, lastPage: lastPage, highlightingSearchAyah: nil)
                },
                navigateToSura: { [weak listener] sura in
                    listener?.navigateTo(page: sura.page, lastPage: nil, highlightingSearchAyah: nil)
                },
                navigateToQuarter: { [weak listener] quarter in
                    listener?.navigateTo(page: quarter.page, lastPage: nil, highlightingSearchAyah: nil)
                },
                syncService: container.syncService
            )
        #else
            let viewModel = HomeViewModel(
                lastPageService: lastPageService,
                textRetriever: textRetriever,
                navigateToPage: { [weak listener] lastPage in
                    listener?.navigateTo(page: lastPage, lastPage: lastPage, highlightingSearchAyah: nil)
                },
                navigateToSura: { [weak listener] sura in
                    listener?.navigateTo(page: sura.page, lastPage: nil, highlightingSearchAyah: nil)
                },
                navigateToQuarter: { [weak listener] quarter in
                    listener?.navigateTo(page: quarter.page, lastPage: nil, highlightingSearchAyah: nil)
                }
            )
        #endif
        let viewController = HomeViewController(
            viewModel: viewModel,
            readingSelectorBuilder: ReadingSelectorBuilder(container: container)
        )
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
