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
        let kind = collection.kind
        let viewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: ayahBookmarkCollectionService,
            collectionID: collection.collection.id,
            navigateToPage: navigateToPage
        )
        return AyahBookmarkCollectionsViewController(
            viewModel: viewModel,
            title: kind.highlightColor?.localizedName ?? collection.collection.name
        )
    }

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let navigateToPage: (Page) -> Void
}
#endif
