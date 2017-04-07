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

    let numberFormatter = NumberFormatter()

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuarterTableViewCell,
                                    with item: Quarter,
                                    at indexPath: IndexPath) {

        let progress = CGFloat(item.order % 4) / 4
        let circleProgress = progress == 0 ? 1 : progress
        let hizb = item.order / 4 + 1

        cell.circleLabel.text = numberFormatter.format(NSNumber(value: hizb))
        cell.circleLabel.isHidden = circleProgress != 1
        cell.circleView.progress = circleProgress
        cell.name.text = item.ayahText
        cell.descriptionLabel.text = item.ayah.localizedName
        cell.startPage.text = numberFormatter.format(NSNumber(value: item.startPageNumber))
    }
}
