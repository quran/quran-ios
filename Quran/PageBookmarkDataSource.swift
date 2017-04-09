//
//  PageBookmarkDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/1/16.
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

class PageBookmarkDataSource: BasicDataSource<PageBookmark, BookmarkTableViewCell> {

    let numberFormatter = NumberFormatter()

    let persistence: BookmarksPersistence

    init(persistence: BookmarksPersistence) {
        self.persistence = persistence
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: BookmarkTableViewCell,
                                    with item: PageBookmark,
                                    at indexPath: IndexPath) {
        let ayah = Quran.startAyahForPage(item.page)

        let suraFormat = NSLocalizedString("quran_sura_title", tableName: "Android", comment: "")
        let suraName = Quran.nameForSura(ayah.sura)

        let pageDescriptionFormat = NSLocalizedString("page_description", tableName: "Android", comment: "")
        let pageDescription = String.localizedStringWithFormat(pageDescriptionFormat, item.page, Juz.juzFromPage(item.page).juzNumber)

        cell.name.text = String(format: suraFormat, suraName)
        cell.descriptionLabel.text = pageDescription
        cell.startPage.text = numberFormatter.format(NSNumber(value: item.page))
    }

    func reloadData() {
        DispatchQueue.global()
            .promise(execute: self.persistence.retrievePageBookmarks)
            .then(on: .main) { items -> Void in
                self.items = items
                self.ds_reusableViewDelegate?.ds_reloadSections(IndexSet(integer: 0), with: .automatic)
        }.cauterize(tag: "BookmarksPersistence.retrievePageBookmarks")
    }
}
