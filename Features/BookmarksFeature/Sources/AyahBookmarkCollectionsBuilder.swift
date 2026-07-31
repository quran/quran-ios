#if QURAN_SYNC
//
//  AyahBookmarkCollectionsBuilder.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import AnnotationsService
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
        navigateToAyah: @escaping (AyahNumber) -> Void
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.quranTextDataService = quranTextDataService
        self.navigateToAyah = navigateToAyah
    }

    func buildCollection(
        _ collection: AyahBookmarkCollection,
        collectionDeleted: @escaping () -> Void
    ) -> UIViewController {
        let viewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: ayahBookmarkCollectionService,
            collection: collection,
            quranTextDataService: quranTextDataService,
            navigateToAyah: navigateToAyah,
            collectionDeleted: collectionDeleted
        )
        return AyahBookmarkCollectionsViewController(viewModel: viewModel)
    }

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let quranTextDataService: QuranTextDataService
    private let navigateToAyah: (AyahNumber) -> Void
}
#endif
