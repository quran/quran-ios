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

    func build(withListener listener: QuranNavigator) -> UIViewController {
        let viewControllerReference = BookmarkCollectionsViewControllerReference()
        let collectionService = AyahBookmarkCollectionService(quranDataService: container.quranDataService)
        let collectionsBuilder = AyahBookmarkCollectionsBuilder(
            ayahBookmarkCollectionService: collectionService,
            navigateToPage: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        let collectionsViewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: collectionService,
            excludedCollectionNames: [AyahBookmarkCollectionName.oldPageBookmarks],
            navigateToPage: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        let viewModel = BookmarkCollectionsViewModel(
            authenticationClient: container.authenticationClient,
            collectionsViewModel: collectionsViewModel,
            loginAction: { [viewControllerReference, authenticationClient = container.authenticationClient] in
                guard let viewController = viewControllerReference.value else {
                    return
                }
                try await authenticationClient.login(on: viewController)
            },
            showOldPageBookmarksAction: { [viewControllerReference, collectionsBuilder] in
                guard let navigationController = viewControllerReference.value?.navigationController else {
                    return
                }
                navigationController.pushViewController(collectionsBuilder.buildOldPageBookmarks(), animated: true)
            }
        )
        let viewController = BookmarkCollectionsViewController(viewModel: viewModel)
        viewControllerReference.value = viewController
        return viewController
    }
}

@MainActor
private final class BookmarkCollectionsViewControllerReference {
    weak var value: BookmarkCollectionsViewController?
}
#endif
