#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionsBuilder.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Localization
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
                excludedCollectionNames: [Self.oldPageBookmarksCollectionName],
                navigateToPage: navigateToPage
            )
            return AyahBookmarkCollectionsViewController(viewModel: viewModel)
        }

        func buildOldPageBookmarks() -> UIViewController {
            let viewModel = AyahBookmarkCollectionsViewModel(
                ayahBookmarkCollectionService: ayahBookmarkCollectionService,
                includedCollectionNames: [Self.oldPageBookmarksCollectionName],
                navigateToPage: navigateToPage
            )
            return AyahBookmarkCollectionsViewController(
                viewModel: viewModel,
                title: l("bookmarks.old-page-bookmarks"),
                allowsCollectionManagement: false,
                allowsBookmarkDeletion: false
            )
        }

        private static let oldPageBookmarksCollectionName = "Old Page Bookmarks"

        private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
        private let navigateToPage: (Page) -> Void
    }
#endif
