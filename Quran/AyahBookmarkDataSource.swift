//
//  AyahBookmarkDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class AyahBookmarkDataSource: BasicDataSource<AyahBookmark, BookmarkTableViewCell> {

    let ayahCache: Cache<AyahNumber, String> = {
        let cache = Cache<AyahNumber, String>()
        cache.countLimit = 30
        return cache
    }()

    let numberFormatter = NumberFormatter()

    let persistence: BookmarksPersistence
    let ayahPersistence: AyahTextPersistence

    init(reuseIdentifier: String, persistence: BookmarksPersistence, ayahPersistence: AyahTextPersistence) {
        self.persistence = persistence
        self.ayahPersistence = ayahPersistence
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: BookmarkTableViewCell,
                                    with item: AyahBookmark,
                                    at indexPath: IndexPath) {

        let suraName = Quran.nameForSura(item.ayah.sura)
        let ayahText = numberFormatter.string(from: NSNumber(value: item.ayah.ayah)) ?? ""
        let juzText = numberFormatter.string(from: NSNumber(value: Juz.juzFromPage(item.page).juzNumber)) ?? ""

        let ayahFormat = NSLocalizedString("quran_ayah_details", tableName: "Android", comment: "")
        let ayahDescription = String.localizedStringWithFormat(ayahFormat, suraName, ayahText, juzText)

        cell.descriptionLabel.text = ayahDescription
        cell.startPage.text = numberFormatter.format(NSNumber(value: item.page))

        // get from cache
        if let text = ayahCache.object(forKey: item.ayah) {
            cell.name.text = text

        } else {
            cell.name.text = item.ayah.localizedName
            DispatchQueue.bookmarks
                .promise { try self.ayahPersistence.getAyahTextForNumber(item.ayah) }
                .then(on: .main) { text -> Void in
                    guard self.ds_reusableViewDelegate?.ds_indexPath(for: cell) == indexPath else { return }

                    // save to cache
                    self.ayahCache.setObject(text, forKey: item.ayah)

                    // update the UI
                    cell.name.text = text
            }.cauterize(tag: "AyahTextPersistence.getAyahTextForNumber")
        }
    }

    func reloadData() {
        DispatchQueue.bookmarks
        .promise(execute: self.persistence.retrieveAyahBookmarks)
            .then(on: .main) { items -> Void in
                self.items = items
                self.ds_reusableViewDelegate?.ds_reloadSections(IndexSet(integer: 0), with: .automatic)
        }.cauterize(tag: "BookmarksPersistence.retrieveAyahBookmarks")
    }
}
