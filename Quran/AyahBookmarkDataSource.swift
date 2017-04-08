//
//  AyahBookmarkDataSource.swift
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

class AyahBookmarkDataSource: BasicDataSource<AyahBookmark, BookmarkTableViewCell> {

    let ayahCache: Cache<AyahNumber, String> = {
        let cache = Cache<AyahNumber, String>()
        cache.countLimit = 30
        return cache
    }()

    let numberFormatter = NumberFormatter()

    let persistence: BookmarksPersistence
    let ayahPersistence: AyahTextPersistence

    init(persistence: BookmarksPersistence, ayahPersistence: AyahTextPersistence) {
        self.persistence = persistence
        self.ayahPersistence = ayahPersistence
        super.init()
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
            DispatchQueue.global()
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
        DispatchQueue.global()
        .promise(execute: self.persistence.retrieveAyahBookmarks)
            .then(on: .main) { items -> Void in
                self.items = items
                self.ds_reusableViewDelegate?.ds_reloadSections(IndexSet(integer: 0), with: .automatic)
        }.cauterize(tag: "BookmarksPersistence.retrieveAyahBookmarks")
    }
}
