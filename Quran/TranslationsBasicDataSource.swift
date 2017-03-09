//
//  TranslationsBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/4/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

protocol TranslationsBasicDataSourceDelegate: class {
    func translationsBasicDataSource(_ dataSource: TranslationsBasicDataSource, onShouldStartDownload translation: TranslationFull)
    func translationsBasicDataSource(_ dataSource: TranslationsBasicDataSource, onShouldCancelDownload translation: TranslationFull)
}

class TranslationsBasicDataSource: BasicDataSource<TranslationFull, TranslationTableViewCell> {

    private let downloader: DownloadManager

    weak var delegate: TranslationsBasicDataSourceDelegate?

    public init(downloader: DownloadManager, reuseIdentifier: String) {
        self.downloader = downloader
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: TranslationTableViewCell,
                                    with item: TranslationFull,
                                    at indexPath: IndexPath) {
        let subtitle = (item.translation.translatorForeign ?? item.translation.translator) ?? ""
        cell.set(title: item.translation.displayName,
                 subtitle: subtitle,
                 needsAmharicFont: item.translation.displayName.lowercased().contains("amharic"))
        cell.downloadButton.setDownloadState(item.downloadState)
        cell.onShouldStartDownload = { [weak self] in
            if let ds = self {
                ds.delegate?.translationsBasicDataSource(ds, onShouldStartDownload: item)
            }
        }

        cell.onShouldCancelDownload = { [weak self] in
            if let ds = self {
                ds.delegate?.translationsBasicDataSource(ds, onShouldCancelDownload: item)
            }
        }
    }
}
