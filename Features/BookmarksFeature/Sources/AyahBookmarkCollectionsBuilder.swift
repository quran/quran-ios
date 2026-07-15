#if QURAN_SYNC
//
//  AyahBookmarkCollectionsBuilder.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import NoorUI
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit

@MainActor
struct AyahBookmarkCollectionsBuilder {
    init(
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        quranTextDataService: QuranTextDataService,
        navigateToPage: @escaping (Page) -> Void
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.quranTextDataService = quranTextDataService
        self.navigateToPage = navigateToPage
    }

    func buildCollection(
        _ collection: AyahBookmarkCollection,
        collectionDeleted: @escaping () -> Void
    ) -> UIViewController {
        let viewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: ayahBookmarkCollectionService,
            collection: collection,
            quranTextDataService: quranTextDataService,
            navigateToPage: navigateToPage,
            collectionDeleted: collectionDeleted
        )
        return AyahBookmarkCollectionsViewController(viewModel: viewModel)
    }

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let quranTextDataService: QuranTextDataService
    private let navigateToPage: (Page) -> Void
}
#endif
