//
//  TranslationsSelectionBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
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

class TranslationsSelectionBasicDataSource: TranslationsBasicDataSource {

    private let simplePersistence: SimplePersistence

    init(simplePersistence: SimplePersistence) {
        self.simplePersistence = simplePersistence
        super.init()
    }

    override var isSelectable: Bool {
        return true
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: TranslationTableViewCell,
                                    with item: TranslationFull,
                                    at indexPath: IndexPath) {
        super.ds_collectionView(collectionView, configure: cell, with: item, at: indexPath)
        cell.checkbox.isHidden = false
        cell.setSelection(simplePersistence.valueForKey(.selectedTranslations).contains(item.translation.id))
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.item(at: indexPath)
        var selectedTranslations = simplePersistence.valueForKey(.selectedTranslations)
        let existingIndex = selectedTranslations.index(of: item.translation.id)
        if let existingIndex = existingIndex {
            selectedTranslations.remove(at: existingIndex)
        } else {
            selectedTranslations.append(item.translation.id)
        }
        simplePersistence.setValue(selectedTranslations, forKey: .selectedTranslations)
        let cell = collectionView.ds_cellForItem(at: indexPath) as? TranslationTableViewCell
        cell?.setSelection(existingIndex == nil)
        collectionView.ds_deselectItem(at: indexPath, animated: true)
    }
}
