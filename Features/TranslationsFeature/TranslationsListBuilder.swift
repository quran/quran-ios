//
//  TranslationsListBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import TranslationService
import UIKit

@MainActor
public struct TranslationsListBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build() async -> UIViewController {
        let repository = TranslationsRepository(databasesURL: container.databasesURL, baseURL: container.appHost)
        let downloader = await container.downloadManager()
        let viewModel = TranslationsListViewModel(
            analytics: container.analytics,
            translationsRepository: repository,
            localTranslationsRetriever: LocalTranslationsRetriever(databasesURL: container.databasesURL),
            deleter: TranslationDeleter(databasesURL: container.databasesURL),
            downloader: TranslationsDownloader(downloader: downloader)
        )

        let viewController = TranslationsViewController(viewModel: viewModel)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
