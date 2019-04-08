//
//  TranslationsListBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol TranslationsListBuildable: Buildable {
    func build(withListener listener: TranslationsListListener) -> TranslationsListRouting
}

final class TranslationsListBuilder: Builder, TranslationsListBuildable {

    func build(withListener listener: TranslationsListListener) -> TranslationsListRouting {
        let viewController = TranslationsViewController(
            translationsRetriever: container.createTranslationsRetriever(),
            localTranslationsRetriever: container.createLocalTranslationsRetriever(),
            dataSource: createTranslationsDataSource())
        let interactor = TranslationsListInteractor(presenter: viewController)
        interactor.listener = listener
        return TranslationsListRouter(interactor: interactor, viewController: viewController)
    }

    func createTranslationsDataSource() -> TranslationsDataSource {
        let pendingDS = TranslationsBasicDataSource()
        let downloadedDS = TranslationsBasicDataSource()
        let dataSource = TranslationsDataSource(
            downloader: container.createDownloadManager(),
            deletionInteractor: container.createTranslationDeletionInteractor(),
            versionUpdater: container.createTranslationsVersionUpdater(),
            pendingDataSource: pendingDS,
            downloadedDataSource: downloadedDS)
        pendingDS.delegate = dataSource
        downloadedDS.delegate = dataSource
        return dataSource
    }
}
