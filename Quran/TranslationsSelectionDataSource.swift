//
//  TranslationsSelectionDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class TranslationsSelectionDataSource: TranslationsDataSource {

    override func ds_collectionView(_ collectionView: GeneralCollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
