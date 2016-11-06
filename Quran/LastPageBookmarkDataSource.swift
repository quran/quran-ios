//
//  LastPageBookmarkDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class LastPageBookmarkDataSource: BasicDataSource<LastPage, BookmarkTableViewCell> {

    let numberFormatter = NumberFormatter()

    let persistence: LastPagesPersistence

    init(reuseIdentifier: String, persistence: LastPagesPersistence) {
        self.persistence = persistence
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: BookmarkTableViewCell,
                                    with item: LastPage,
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
        Queue.bookmarks.async({ self.persistence.retrieveAll() }) { [weak self] items in
            self?.items = items
            self?.ds_reusableViewDelegate?.ds_reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}
