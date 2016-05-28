//
//  QuartersDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuartersDataSource: BasicDataSource<Quarter, QuarterTableViewCell> {

    let numberFormatter = NSNumberFormatter()

    // this is needed as of swift 2.2 as class don't inherit constructors from generic based.
    override init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView,
                                    configureCell cell: QuarterTableViewCell,
                                    withItem item: Quarter,
                                    atIndexPath indexPath: NSIndexPath) {

        let progress = CGFloat(item.order % 4) / 4
        let circleProgress = progress == 0 ? 1 : progress
        let hizb = item.order / 4 + 1

        cell.circleLabel.text = numberFormatter.format(hizb)
        cell.circleLabel.hidden = circleProgress != 1
        cell.circleView.progress = circleProgress
        cell.name.text = item.ayahText
        cell.descriptionLabel.text = item.ayah.localizedName
        cell.startPage.text = numberFormatter.format(item.startPageNumber)
    }
}
