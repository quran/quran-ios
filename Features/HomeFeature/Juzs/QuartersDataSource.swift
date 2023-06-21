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
import NoorUI
import QuranKit
import UIKit
import UIx

class QuartersDataSource: BasicDataSource<(quarter: Quarter, text: String), HostingTableViewCell<HomeQuarterCell>> {
    weak var controller: UIViewController?

    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: HostingTableViewCell<HomeQuarterCell>,
        with item: (quarter: Quarter, text: String),
        at indexPath: IndexPath
    ) {
        guard let controller else {
            return
        }
        let text = item.text
        let item = item.quarter
        let lastItem = items.last!.quarter
        let quarterCell = HomeQuarterCell(
            page: item.page.pageNumber,
            maxPage: lastItem.page.pageNumber,
            text: text,
            localizedVerse: item.firstVerse.localizedName,
            arabicSuraName: item.firstVerse.sura.arabicSuraName,
            localizedQuarter: item.localizedName,
            maxLocalizedQuarter: lastItem.localizedName
        )

        cell.set(rootView: quarterCell, parentController: controller)
    }
}
