//
//  QuranTranslationSuraDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

class QuranTranslationSuraDataSource: BasicDataSource<String, QuranTranslationSuraNameCollectionViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranTranslationSuraNameCollectionViewCell,
                                    with item: String,
                                    at indexPath: IndexPath) {
        cell.label.text = item
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.ds_scrollView.bounds.width, height: 64)
    }
}
