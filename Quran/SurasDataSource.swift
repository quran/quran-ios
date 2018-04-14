//
//  SurasDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
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

class SurasDataSource: BasicDataSource<Sura, SuraTableViewCell> {

    let numberFormatter = NumberFormatter()

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: SuraTableViewCell,
                                    with item: Sura,
                                    at indexPath: IndexPath) {

        let ayahsString = String.localizedStringWithFormat(lAndroid("verses"), item.numberOfAyahs)
        let suraType = item.isMAkki ? lAndroid("makki") : lAndroid("madani")

        cell.order.text = numberFormatter.format(NSNumber(value: item.suraNumber))
        cell.name.text = Quran.nameForSura(item.suraNumber)
        cell.descriptionLabel.text = "\(suraType) - \(ayahsString)"
        cell.startPage.text = numberFormatter.format(NSNumber(value: item.startPageNumber))
    }
}
