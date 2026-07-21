#if QURAN_SYNC
//
//  BookmarkCollectionsBuilder.swift
//

import AppDependencies
import FeaturesSupport
import QuranKit
import UIKit

@MainActor
struct BookmarkCollectionsBuilder {
    let container: AppDependencies

    func build(
        withListener listener: QuranNavigator,
        navigationController: UINavigationController
    ) -> UIViewController {
        let collectionService = AyahBookmarkCollectionService(quranDataService: container.quranDataService)
        let collectionsBuilder = AyahBookmarkCollectionsBuilder(
            ayahBookmarkCollectionService: collectionService,
            quranTextDataService: container.textDataService(),
            navigateToPage: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        let viewModel = BookmarkCollectionsViewModel(
            authenticationClient: container.authenticationClient,
            ayahBookmarkCollectionService: collectionService,
            readingBookmarkService: container.readingBookmarkService(),
            collectionsBuilder: collectionsBuilder,
            navigationController: navigationController,
            navigateToPage: { [weak listener] page, ayah in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: ayah)
            }
        )
        return BookmarkCollectionsViewController(viewModel: viewModel)
    }
}
#endif
