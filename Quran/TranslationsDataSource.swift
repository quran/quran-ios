//
//  TranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class TranslationsDataSource: BasicDataSource<TranslationFull, TranslationTableViewCell> {

    private let downloader: DownloadManager
    public init(downloader: DownloadManager, reuseIdentifier: String) {
        self.downloader = downloader
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: TranslationTableViewCell,
                                    with item: TranslationFull,
                                    at indexPath: IndexPath) {
        cell.set(title: item.translation.displayName, subtitle: (item.translation.translatorForeign ?? item.translation.translator) ?? "")
        cell.downloadButton.setDownloadState(item.downloadState)
        cell.onShouldStartDownload = { [weak self] in
            guard let `self` = self else { return }

            // download the translation
            let destinationPath = Files.translationsPathComponent.stringByAppendingPath(item.translation.rawFileName)
            let download = Download(url: item.translation.fileURL, resumePath: destinationPath.resumePath, destinationPath: destinationPath)
            let responses = self.downloader.download([download])

            guard let response = responses.first, self.items.count > indexPath.item else {
                return
            }

            let newItem = TranslationFull(translation: item.translation, downloaded: false, downloadResponse: response)
            var newItems = self.items
            newItems[indexPath.item] = newItem
            self.items = newItems
        }

        cell.onShouldCancelDownload = {

        }
    }
}
