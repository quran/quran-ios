#if QURAN_SYNC
//
//  BookmarkCollectionsLandingBuilder.swift
//

import AppDependencies
import FeaturesSupport
import QuranKit
import UIKit

@MainActor
struct BookmarkCollectionsLandingBuilder {
    let container: AppDependencies

    func build(withListener listener: QuranNavigator) -> UIViewController {
        let viewControllerReference = BookmarkCollectionsLandingViewControllerReference()
        let collectionService = AyahBookmarkCollectionService(quranDataService: container.quranDataService)
        let collectionsBuilder = AyahBookmarkCollectionsBuilder(
            ayahBookmarkCollectionService: collectionService,
            navigateToPage: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        let viewModel = BookmarkCollectionsLandingViewModel(
            authenticationClient: container.authenticationClient,
            collectionService: collectionService,
            loginAction: { [viewControllerReference, authenticationClient = container.authenticationClient] in
                guard let viewController = viewControllerReference.value else {
                    return
                }
                try await authenticationClient.login(on: viewController)
            },
            showCollectionsAction: { [viewControllerReference, collectionsBuilder] in
                guard let navigationController = viewControllerReference.value?.navigationController else {
                    return
                }
                navigationController.pushViewController(collectionsBuilder.build(), animated: true)
            },
            showOldPageBookmarksAction: { [viewControllerReference, collectionsBuilder] in
                guard let navigationController = viewControllerReference.value?.navigationController else {
                    return
                }
                navigationController.pushViewController(collectionsBuilder.buildOldPageBookmarks(), animated: true)
            }
        )
        let viewController = BookmarkCollectionsLandingViewController(viewModel: viewModel)
        viewControllerReference.value = viewController
        return viewController
    }
}

@MainActor
private final class BookmarkCollectionsLandingViewControllerReference {
    weak var value: BookmarkCollectionsLandingViewController?
}
#endif
