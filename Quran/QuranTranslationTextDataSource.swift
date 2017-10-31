//
//  QuranTranslationTextDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
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

import GenericDataSources

class QuranTranslationTextDataSource: BasicDataSource<TranslationTextLayout, QuranTranslationTextCollectionViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranTranslationTextCollectionViewCell,
                                    with item: TranslationTextLayout,
                                    at indexPath: IndexPath) {
        cell.label.attributedText = item.text.attributedText
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.item(at: indexPath)
        return CGSize(width: collectionView.ds_scrollView.bounds.width,
                      height: item.size.height +
                        QuranTranslationTextCollectionViewCell.topPadding +
                        QuranTranslationTextCollectionViewCell.bottomPadding)
    }
}
