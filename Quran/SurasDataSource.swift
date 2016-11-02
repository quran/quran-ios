//
//  SurasDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class SurasDataSource: BasicDataSource<Sura, SuraTableViewCell> {

    let numberFormatter = NumberFormatter()

    // this is needed as of swift 2.2 as class don't inherit constructors from generic based.
    override init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: SuraTableViewCell,
                                    with item: Sura,
                                    at indexPath: IndexPath) {

        let ayahsString = String.localizedStringWithFormat(NSLocalizedString("verses", tableName: "Android", comment: ""), item.numberOfAyahs)
        let makki = NSLocalizedString("makki", tableName: "Android", comment: "")
        let madani = NSLocalizedString("madani", tableName: "Android", comment: "")
        let suraType = item.isMAkki ? makki : madani

        cell.order.text = numberFormatter.format(NSNumber(value: item.suraNumber))
        cell.name.text = Quran.nameForSura(item.suraNumber)
        cell.descriptionLabel.text = "\(suraType) - \(ayahsString)"
        cell.startPage.text = numberFormatter.format(NSNumber(value: item.startPageNumber))
    }
}
