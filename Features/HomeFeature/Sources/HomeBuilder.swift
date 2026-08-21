//
//  HomeBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import Combine
import FeaturesSupport
import NoorUI
import QuranTextKit
import ReadingSelectorFeature
import ReadingService
import UIKit

@MainActor
public struct HomeBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        let readingPreferences = ReadingPreferences.shared
        let quranFontSource = QuranFontSource(
            current: { readingPreferences.reading.quranFont },
            updates: readingPreferences.$reading.map(\.quranFont)
        )
        let textRetriever = QuranTextDataService(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        #if QURAN_SYNC
        let viewModel = HomeViewModel(
            lastPageService: container.lastPageService(),
            textRetriever: textRetriever,
            readingBookmarkService: container.readingBookmarkService(),
            quranFontSource: quranFontSource,
            navigateToPage: { [weak listener] page, lastPage in
                listener?.navigateTo(page: page, lastPage: lastPage)
            },
            navigateToAyah: { [weak listener] ayah in
                listener?.navigateTo(ayah: ayah, lastPage: nil)
            }
        )
        #else
        let viewModel = HomeViewModel(
            lastPageService: container.lastPageService(),
            textRetriever: textRetriever,
            quranFontSource: quranFontSource,
            navigateToPage: { [weak listener] page, lastPage in
                listener?.navigateTo(page: page, lastPage: lastPage)
            },
            navigateToAyah: { [weak listener] ayah in
                listener?.navigateTo(ayah: ayah, lastPage: nil)
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
