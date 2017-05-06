//
//  LastPageBookmarkDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
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

class LastPageBookmarkDataSource: BasicDataSource<LastPage, BookmarkTableViewCell> {

    let numberFormatter = NumberFormatter()

    let persistence: LastPagesPersistence

    init(persistence: LastPagesPersistence) {
        self.persistence = persistence
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: BookmarkTableViewCell,
                                    with item: LastPage,
                                    at indexPath: IndexPath) {
        let ayah = Quran.startAyahForPage(item.page)

        cell.iconImage.image = #imageLiteral(resourceName: "recent")
        cell.name.text = Quran.nameForSura(ayah.sura, withPrefix: true)
        cell.descriptionLabel.text = item.modifiedOn.bookmarkTimeAgo()
        cell.startPage.text = numberFormatter.format(NSNumber(value: item.page))
    }

    func reloadData() {
        DispatchQueue.default
            .promise2(execute: self.persistence.retrieveAll)
            .then(on: .main) { items -> Void in
                self.items = items
                self.ds_reusableViewDelegate?.ds_reloadSections(IndexSet(integer: 0), with: .automatic)
            }.cauterize(tag: "LastPagesPersistence.retrieveAll")
    }
}
