//
//  TranslationsSelectionBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol TranslationsSelectionBuildble: Buildable {
    func build(withListener listener: TranslationsListListener) -> TranslationsListRouting
}

final class TranslationsSelectionBuilder: Builder, TranslationsSelectionBuildble {

    func build(withListener listener: TranslationsListListener) -> TranslationsListRouting {
        let viewController = TranslationsSelectionViewController(
            interactor: container.createTranslationsRetrievalInteractor(),
            localTranslationsInteractor: container.createLocalTranslationsRetrievalInteractor(),
            dataSource: createTranslationsSelectionDataSource())
        let interactor = TranslationsListInteractor(presenter: viewController)
        interactor.listener = listener
        return TranslationsListRouter(interactor: interactor, viewController: viewController)
    }

    private func createTranslationsSelectionDataSource() -> TranslationsDataSource {
        let pendingDS = TranslationsBasicDataSource()
        let downloadedDS = TranslationsSelectionBasicDataSource(
            simplePersistence: container.createSimplePersistence())
        let dataSource = TranslationsSelectionDataSource(
            downloader: container.createDownloadManager(),
            deletionInteractor: container.createTranslationDeletionInteractor(),
            versionUpdater: container.createTranslationsVersionUpdaterInteractor(),
            pendingDataSource: pendingDS,
            downloadedDataSource: downloadedDS)
        pendingDS.delegate = dataSource
        downloadedDS.delegate = dataSource
        return dataSource
    }
}
