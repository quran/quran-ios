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
        let viewModel = BookmarksViewModel(
            analytics: container.analytics,
            service: service,
            authenticationClient: container.authenticationClient,
            navigateTo: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        let viewController = BookmarksViewController(viewModel: viewModel)
        #if QURAN_SYNC
            let collectionsBuilder = CollectionsBuilder(container: container)
            viewController.onOpenCollections = { [weak viewController, weak listener] in
                guard let listener else {
                    return
                }
                let collectionsViewController = collectionsBuilder.build(withListener: listener)
                viewController?.navigationController?.pushViewController(collectionsViewController, animated: true)
            }
        #endif
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
