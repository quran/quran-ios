#if QURAN_SYNC
//
//  BookmarkCollectionsBuilder.swift
//

import AnnotationsService
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
        let collectionService = container.ayahBookmarkCollectionService()
        let highlightService = container.ayahHighlightService()
        let ayahSetBuilder = AyahSetBuilder(
            ayahBookmarkCollectionService: collectionService,
            ayahHighlightService: highlightService,
            quranTextDataService: container.textDataService(),
            navigateToAyah: { [weak listener] ayah in
                listener?.navigateTo(ayah: ayah, lastPage: nil)
            }
        )
        let viewModel = BookmarkCollectionsViewModel(
            analytics: container.analytics,
            authenticationClient: container.authenticationClient,
            ayahBookmarkCollectionService: collectionService,
            ayahHighlightService: highlightService,
            readingBookmarkService: container.readingBookmarkService(),
            ayahSetBuilder: ayahSetBuilder,
            navigationController: navigationController,
            navigateToPage: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil)
            },
            navigateToAyah: { [weak listener] ayah in
                listener?.navigateTo(ayah: ayah, lastPage: nil)
            }
        )
        return BookmarkCollectionsViewController(viewModel: viewModel)
    }
}
#endif
