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

    let numberFormatter = NSNumberFormatter()

    let persistence: SimplePersistence

    init(reuseIdentifier: String, persistence: SimplePersistence) {
        self.persistence = persistence
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView,
                                    configureCell cell: BookmarkTableViewCell,
                                                  withItem item: Int,
                                                           atIndexPath indexPath: NSIndexPath) {
        let ayah = Quran.startAyahForPage(item)

        let suraFormat = NSLocalizedString("quran_sura_title", tableName: "Android", comment: "")
        let suraName = Quran.nameForSura(ayah.sura)

        let pageDescriptionFormat = NSLocalizedString("page_description", tableName: "Android", comment: "")
        let pageDescription = String.localizedStringWithFormat(pageDescriptionFormat, item, Juz.juzFromPage(item).order)

        cell.name.text = String(format: suraFormat, suraName)
        cell.descriptionLabel.text = pageDescription
        cell.startPage.text = numberFormatter.format(item)
    }

    func reloadData() {
        if let item = persistence.valueForKey(.LastViewedPage) {
            items = [item]
        } else {
            items = []
        }
        ds_reusableViewDelegate?.ds_reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
}
