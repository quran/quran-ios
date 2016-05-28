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

    let numberFormatter = NSNumberFormatter()

    // this is needed as of swift 2.2 as class don't inherit constructors from generic based.
    override init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView,
                                    configureCell cell: SuraTableViewCell,
                                    withItem item: Sura,
                                    atIndexPath indexPath: NSIndexPath) {

        let ayahsString = String.localizedStringWithFormat(NSLocalizedString("verses", tableName: "Android", comment: ""), item.numberOfAyahs)
        let makki = NSLocalizedString("makki", tableName: "Android", comment: "")
        let madani = NSLocalizedString("madani", tableName: "Android", comment: "")
        let suraType = item.isMAkki ? makki : madani

        cell.order.text = numberFormatter.format(item.order)
        cell.name.text = Quran.nameForSura(item.order)
        cell.descriptionLabel.text = "\(suraType) - \(ayahsString)"
        cell.startPage.text = numberFormatter.format(item.startPageNumber)
    }
}
