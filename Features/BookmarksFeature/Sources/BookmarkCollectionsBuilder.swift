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
            navigateToPage: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        let viewModel = BookmarkCollectionsViewModel(
            authenticationClient: container.authenticationClient,
            ayahBookmarkCollectionService: collectionService,
            collectionsBuilder: collectionsBuilder,
            navigationController: navigationController
        )
        return BookmarkCollectionsViewController(viewModel: viewModel)
    }
}
#endif
