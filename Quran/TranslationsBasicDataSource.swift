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
    func translationsBasicDataSource(_ dataSource: AbstractDataSource, onShouldStartDownload translation: TranslationFull)
    func translationsBasicDataSource(_ dataSource: AbstractDataSource, onShouldCancelDownload translation: TranslationFull)
}

class TranslationsBasicDataSource: BasicDataSource<TranslationFull, TranslationTableViewCell> {

    weak var delegate: TranslationsBasicDataSourceDelegate?

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: TranslationTableViewCell,
                                    with item: TranslationFull,
                                    at indexPath: IndexPath) {
        cell.checkbox.isHidden = true
        cell.configure(with: item.translation)
        cell.downloadButton.state = item.state
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

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
