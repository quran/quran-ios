//
//  TranslationsBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/4/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
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
