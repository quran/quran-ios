//
//  TranslationsSelectionBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class TranslationsSelectionBasicDataSource: TranslationsBasicDataSource {

    private let simplePersistence: SimplePersistence

    init(simplePersistence: SimplePersistence) {
        self.simplePersistence = simplePersistence
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: TranslationTableViewCell,
                                    with item: TranslationFull,
                                    at indexPath: IndexPath) {
        super.ds_collectionView(collectionView, configure: cell, with: item, at: indexPath)
        cell.checkbox.isHidden = false
        cell.setSelection(simplePersistence.valueForKey(.selectedTranslations).contains(item.translation.id))
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
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
