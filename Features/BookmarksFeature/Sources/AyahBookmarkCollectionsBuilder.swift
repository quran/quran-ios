#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionsBuilder.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

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

        func build() -> UIViewController {
            let viewModel = AyahBookmarkCollectionsViewModel(
                ayahBookmarkCollectionService: ayahBookmarkCollectionService,
                navigateToPage: navigateToPage
            )
            return AyahBookmarkCollectionsViewController(viewModel: viewModel)
        }

        private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
        private let navigateToPage: (Page) -> Void
    }
#endif
