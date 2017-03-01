//
//  TranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class TranslationsDataSource: BasicDataSource<Translation, TranslationTableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: TranslationTableViewCell,
                                    with item: Translation,
                                    at indexPath: IndexPath) {
        cell.set(title: item.displayName, subtitle: (item.translatorForeign ?? item.translator) ?? "")
        cell.downloadButton.setDownloadState(indexPath.item % 2 == 0 ? .startDownload : .pending)
    }
}
