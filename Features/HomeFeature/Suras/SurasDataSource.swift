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
import Localization
import NoorUI
import QuranKit
import UIKit
import UIx

class SurasDataSource: BasicDataSource<Sura, HostingTableViewCell<HomeSuraCell>> {
    weak var controller: UIViewController?

    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: HostingTableViewCell<HomeSuraCell>,
        with item: Sura,
        at indexPath: IndexPath
    ) {
        guard let controller else {
            return
        }
        let ayahsString = lFormat("verses", table: .android, item.verses.count)
        let suraType = item.isMakki ? lAndroid("makki") : lAndroid("madani")

        let lastItem = items.last!

        let suraCell = HomeSuraCell(
            page: item.page.pageNumber,
            localizedSuraNumber: item.localizedSuraNumber,
            maxLocalizedSuraNumber: lastItem.localizedSuraNumber,
            localizedSura: item.localizedName(),
            arabicSuraName: item.arabicSuraName,
            subtitle: "\(suraType) - \(ayahsString)"
        )
        cell.set(rootView: suraCell, parentController: controller)
    }
}
