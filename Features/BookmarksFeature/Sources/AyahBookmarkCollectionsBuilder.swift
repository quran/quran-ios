#if QURAN_SYNC
//
//  AyahBookmarkCollectionsBuilder.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import NoorUI
import QuranAnnotations
import QuranKit
import UIKit

@MainActor
struct AyahBookmarkCollectionsBuilder {
    init(
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        navigateToPage: @escaping (Page) -> Void
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.navigateToPage = navigateToPage
    }

    func buildCollection(_ collection: AyahBookmarkCollection) -> UIViewController {
        let highlightColor = HighlightColor(collectionName: collection.collection.name)
        let isOldPageBookmarks = collection.collection.name == AyahBookmarkCollectionName.oldPageBookmarks
        let viewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: ayahBookmarkCollectionService,
            collectionLocalID: collection.collection.localId,
            navigateToPage: navigateToPage
        )
        return AyahBookmarkCollectionsViewController(
            viewModel: viewModel,
            title: highlightColor?.localizedName ?? collection.collection.name,
            allowsBookmarkDeletion: !isOldPageBookmarks
        )
    }

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let navigateToPage: (Page) -> Void
}
#endif
