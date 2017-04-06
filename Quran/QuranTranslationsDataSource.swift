//
//  QuranTranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
