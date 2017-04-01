//
//  QuranTranslationVerseSeparatorDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

class QuranTranslationVerseSeparatorDataSource: BaseBasicDataSource<(), QuranTranslationVerseSeparatorCollectionViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.ds_scrollView.bounds.width, height: 16)
    }
}
