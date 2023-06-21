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

    public func build(showEditButton: Bool) async -> UIViewController {
        let repository = TranslationService.TranslationsRepository(databasesURL: container.databasesURL, baseURL: container.appHost)
        let interactor = await TranslationsListInteractor(
            analytics: container.analytics,
            translationsRepository: repository,
            localTranslationsRetriever: TranslationService.LocalTranslationsRetriever(databasesURL: container.databasesURL),
            deleter: TranslationService.TranslationDeleter(databasesURL: container.databasesURL),
            downloader: TranslationService.TranslationsDownloader(downloader: container.downloadManager())
        )
        let viewController = TranslationsViewController(showEditButton: showEditButton, interactor: interactor)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
