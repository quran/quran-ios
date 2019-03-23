//
//  QuranImagesDataSource.swift
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

class QuranImagesDataSource: QuranBaseBasicDataSource<QuranImagePageCollectionViewCell>, QuranDataSourceHandler {

    private let imageService: AnyCacheableService<Int, QuranUIImage>
    private let ayahInfoRetriever: AyahInfoRetriever

    private let numberFormatter = NumberFormatter()

    private var highlightedAyat: Set<AyahNumber> = Set()

    init(imageService: AnyCacheableService<Int, QuranUIImage>,
         ayahInfoRetriever: AyahInfoRetriever,
         bookmarkPersistence: BookmarksPersistence) {
        self.imageService = imageService
        self.ayahInfoRetriever = ayahInfoRetriever
        super.init(bookmarkPersistence: bookmarkPersistence)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranImagePageCollectionViewCell,
                                    with item: QuranPage,
                                    at indexPath: IndexPath) {
        // configure the super
        super.ds_collectionView(collectionView, configure: cell, with: item, at: indexPath)

        // configure the cell
        cell.pageLabel.text = numberFormatter.format(NSNumber(value: item.pageNumber))
        cell.suraLabel.text = Quran.nameForSura(item.startAyah.sura)
        cell.juzLabel.text = String(format: lAndroid("juz2_description"), numberFormatter.format(item.juzNumber))

        // set the page image
        imageService.getOnMainThread(item.pageNumber) { [weak cell] image in
            guard cell?.page == item else { return }

            // make sure theme didn't change
            guard image?.theme == Theme.current else {
                return
            }
            cell?.mainImageView.image = image?.image
        }

        // set the ayah dimensions
        ayahInfoRetriever
            .retrieveAyahs(in: item.pageNumber)
            .done(on: .main) { [weak cell] data -> Void in
                guard cell?.page == item else { return }
                cell?.setAyahInfo(data)
            }.cauterize(tag: "retrieveAyahs(in:)")
    }

    func invalidate() {
        imageService.invalidate()
    }
}
