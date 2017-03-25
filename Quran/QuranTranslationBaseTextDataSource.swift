//
//  QuranTranslationBaseTextDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/25/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

protocol TextReusableCell: ReusableCell {
    var label: UILabel! { get }
}

class QuranTranslationBaseTextDataSource<CellType: TextReusableCell>: BasicDataSource<String, CellType> {

    init() {
        super.init(reuseIdentifier: CellType.reuseId)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: CellType,
                                    with item: String,
                                    at indexPath: IndexPath) {
        cell.label.text = item
    }
}
