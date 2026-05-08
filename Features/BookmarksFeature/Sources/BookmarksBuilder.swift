//
//  BookmarksBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import FeaturesSupport
import UIKit

@MainActor
public struct BookmarksBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        let service = PageBookmarkService(persistence: container.pageBookmarkPersistence)
        #if QURAN_SYNC
            let showCollectionsAction: (@MainActor (UIViewController) async -> Void)?
            let showOldPageBookmarksAction: (@MainActor (UIViewController) async -> Void)?
            if let syncService = container.syncService {
                let ayahBookmarkCollectionService = AyahBookmarkCollectionService(syncService: syncService)
                let collectionsBuilder = AyahBookmarkCollectionsBuilder(
                    ayahBookmarkCollectionService: ayahBookmarkCollectionService,
                    navigateToPage: { [weak listener] page in
                        listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
                    }
                )
                showCollectionsAction = { presenter in
                    guard let navigationController = presenter.navigationController else {
                        return
                    }
                    let collectionsViewController = collectionsBuilder.build()
                    navigationController.pushViewController(collectionsViewController, animated: true)
                }
                showOldPageBookmarksAction = { presenter in
                    guard let navigationController = presenter.navigationController else {
                        return
                    }
                    let oldPageBookmarksViewController = collectionsBuilder.buildOldPageBookmarks()
                    navigationController.pushViewController(oldPageBookmarksViewController, animated: true)
                }
            } else {
                showCollectionsAction = nil
                showOldPageBookmarksAction = nil
            }
            let viewModel = BookmarksViewModel(
                analytics: container.analytics,
                service: service,
                authenticationClient: container.authenticationClient,
                navigateTo: { [weak listener] page in
                    listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
                },
                showCollectionsAction: showCollectionsAction,
                showOldPageBookmarksAction: showOldPageBookmarksAction
            )
        #else
            let viewModel = BookmarksViewModel(
                analytics: container.analytics,
                service: service,
                authenticationClient: container.authenticationClient,
                navigateTo: { [weak listener] page in
                    listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
                }
            )
        #endif

        return BookmarksViewController(viewModel: viewModel)
    }

    // MARK: Internal

    let container: AppDependencies
}
