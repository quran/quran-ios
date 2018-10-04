//
//  QuranTranslationLongTextDataSource.swift
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

class QuranTranslationLongTextDataSource: BasicDataSource<TranslationTextLayout, QuranTranslationLongTextCollectionViewCell> {
    private let fontSize: FontSize
    init(fontSize: FontSize) {
        self.fontSize = fontSize
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranTranslationLongTextCollectionViewCell,
                                    with item: TranslationTextLayout,
                                    at indexPath: IndexPath) {
        cell.label.setTextLayout(item, fontSize: fontSize)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.item(at: indexPath)
        return CGSize(width: collectionView.ds_scrollView.bounds.width,
                      height: item.size.height +
                        QuranTranslationLongTextCollectionViewCell.topPadding +
                        QuranTranslationLongTextCollectionViewCell.bottomPadding)
    }
}
