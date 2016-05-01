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
        let descriptionFormat = NSLocalizedString("suraDescriptionMakkiAndVerses", comment: "")
        let makki = NSLocalizedString("makki", comment: "")
        let madani = NSLocalizedString("madani", comment: "")

        cell.order.text = numberFormatter.format(item.order)
        cell.name.text = NSLocalizedString("sura_names[\(item.order - 1)]", comment: "")
        cell.descriptionLabel.text = String(format: descriptionFormat, item.isMAkki ? makki : madani, numberFormatter.format(item.numberOfAyahs))
        cell.startPage.text = numberFormatter.format(item.startPageNumber)
    }
}
