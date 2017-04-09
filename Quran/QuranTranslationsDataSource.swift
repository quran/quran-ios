//
//  QuranTranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
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

class QuranTranslationsDataSource: QuranBaseBasicDataSource<QuranTranslationCollectionPageCollectionViewCell>, QuranDataSourceHandler {

    private let pageService: AnyCacheableService<Int, TranslationPage>
    private let ayahInfoRetriever: AyahInfoRetriever
    private let bookmarkPersistence: BookmarksPersistence

    private let numberFormatter = NumberFormatter()

    private var highlightedAyat: Set<AyahNumber> = Set()

    init(
         pageService         : AnyCacheableService<Int, TranslationPage>,
         ayahInfoRetriever   : AyahInfoRetriever,
         bookmarkPersistence : BookmarksPersistence) {
        self.bookmarkPersistence = bookmarkPersistence
        self.pageService         = pageService
        self.ayahInfoRetriever   = ayahInfoRetriever
        super.init(bookmarkPersistence: bookmarkPersistence)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranTranslationCollectionPageCollectionViewCell,
                                    with item: QuranPage,
                                    at indexPath: IndexPath) {
        // configure the super
        super.ds_collectionView(collectionView, configure: cell, with: item, at: indexPath)

        // set the translation page
        pageService.getOnMainThread(item.pageNumber) { [weak cell] page in
            guard cell?.page == item else { return }
            cell?.translationPage = page
        }
    }

    func invalidate() {
        pageService.invalidate()
    }
}
