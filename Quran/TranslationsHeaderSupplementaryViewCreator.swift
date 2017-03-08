//
//  TranslationsHeaderSupplementaryViewCreator.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/4/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class TranslationsHeaderSupplementaryViewCreator: BasicSupplementaryViewCreator<String, JuzTableViewHeaderFooterView> {

    override init(identifier: String) {
        super.init(identifier: identifier, size: CGSize(width: 0, height: 44))
    }

    override func collectionView(_ collectionView: GeneralCollectionView,
                                 configure view: JuzTableViewHeaderFooterView,
                                 with item: String,
                                 at indexPath: IndexPath) {

        view.titleLabel.text = item
        view.subtitleLabel.isHidden = true
    }
}
