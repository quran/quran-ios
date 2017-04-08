//
//  TranslationsHeaderSupplementaryViewCreator.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/4/17.
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

class TranslationsHeaderSupplementaryViewCreator: BasicSupplementaryViewCreator<String, JuzTableViewHeaderFooterView> {

    override init() {
        super.init(size: CGSize(width: 0, height: 44))
    }

    override func collectionView(_ collectionView: GeneralCollectionView,
                                 configure view: JuzTableViewHeaderFooterView,
                                 with item: String,
                                 at indexPath: IndexPath) {

        view.titleLabel.text = item
        view.subtitleLabel.isHidden = true
    }
}
