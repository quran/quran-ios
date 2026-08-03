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
        let collectionService = AyahBookmarkCollectionService(quranDataService: container.quranDataService)
        let collectionsBuilder = AyahBookmarkCollectionsBuilder(
            ayahBookmarkCollectionService: collectionService,
            quranTextDataService: container.textDataService(),
            navigateToAyah: { [weak listener] ayah in
                listener?.navigateTo(ayah: ayah, lastPage: nil)
            }
        )
        let viewModel = BookmarkCollectionsViewModel(
            authenticationClient: container.authenticationClient,
            ayahBookmarkCollectionService: collectionService,
            readingBookmarkService: container.readingBookmarkService(),
            collectionsBuilder: collectionsBuilder,
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
