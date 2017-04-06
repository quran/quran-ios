//
//  QuranTranslationArabicTextDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

class QuranTranslationArabicTextDataSource: BasicDataSource<TranslationArabicTextLayout, QuranTranslationArabicTextCollectionViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranTranslationArabicTextCollectionViewCell,
                                    with item: TranslationArabicTextLayout,
                                    at indexPath: IndexPath) {
        cell.label.text = item.arabicText
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.item(at: indexPath)
        return CGSize(width: collectionView.ds_scrollView.bounds.width, height: item.size.height + 30)
    }
}
