//
//  LastPageBookmarkDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class LastPageBookmarkDataSource: BasicDataSource<Int, BookmarkTableViewCell> {

    let numberFormatter = NumberFormatter()

    let persistence: SimplePersistence

    init(reuseIdentifier: String, persistence: SimplePersistence) {
        self.persistence = persistence
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: BookmarkTableViewCell,
                                    with item: Int,
                                    at indexPath: IndexPath) {
        let ayah = Quran.startAyahForPage(item)

        let suraFormat = NSLocalizedString("quran_sura_title", tableName: "Android", comment: "")
        let suraName = Quran.nameForSura(ayah.sura)

        let pageDescriptionFormat = NSLocalizedString("page_description", tableName: "Android", comment: "")
        let pageDescription = String.localizedStringWithFormat(pageDescriptionFormat, item, Juz.juzFromPage(item).order)

        cell.name.text = String(format: suraFormat, suraName)
        cell.descriptionLabel.text = pageDescription
        cell.startPage.text = numberFormatter.format(NSNumber(value: item))
    }

    func reloadData() {
        if let item = persistence.valueForKey(.LastViewedPage) {
            items = [item]
        } else {
            items = []
        }
        ds_reusableViewDelegate?.ds_reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}
