//
//  QuranTranslationTranslatorNameTextDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

class QuranTranslationTranslatorNameTextDataSource: BasicDataSource<TranslationTextLayout, QuranTranslationTranslatorNameCollectionViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranTranslationTranslatorNameCollectionViewCell,
                                    with item: TranslationTextLayout,
                                    at indexPath: IndexPath) {
        cell.label.font = item.text.translation.preferredTranslatorNameFont
        cell.label.text = item.text.translation.translationName
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.item(at: indexPath)
        return CGSize(width: collectionView.ds_scrollView.bounds.width, height: item.translatorSize.height + 20)
    }
}
