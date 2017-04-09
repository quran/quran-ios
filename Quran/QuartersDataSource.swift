//
//  QuartersDataSource.swift
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
