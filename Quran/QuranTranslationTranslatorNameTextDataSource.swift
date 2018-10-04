//
//  QuranTranslationTranslatorNameTextDataSource.swift
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

class QuranTranslationTranslatorNameTextDataSource: BasicDataSource<TranslationTextLayout, QuranTranslationTranslatorNameCollectionViewCell> {
    private let fontSize: FontSize
    init(fontSize: FontSize) {
        self.fontSize = fontSize
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranTranslationTranslatorNameCollectionViewCell,
                                    with item: TranslationTextLayout,
                                    at indexPath: IndexPath) {
        cell.label.font = item.text.translation.preferredTranslatorNameFont(ofSize: fontSize)
        cell.label.text = item.text.translation.translationName
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.item(at: indexPath)
        return CGSize(width: collectionView.ds_scrollView.bounds.width,
                      height: item.translatorSize.height +
                        QuranTranslationTranslatorNameCollectionViewCell.topPadding +
                        QuranTranslationTranslatorNameCollectionViewCell.bottomPadding)
    }
}
