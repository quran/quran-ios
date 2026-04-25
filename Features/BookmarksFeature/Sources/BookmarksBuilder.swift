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
            highlightCollectionsUpdates: makeHighlightCollectionsUpdates(),
            authenticationClient: container.authenticationClient,
            navigateTo: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            },
            makeHighlightsController: makeHighlightsController(listener: listener)
        )
        let viewController = BookmarksViewController(viewModel: viewModel)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies

    // MARK: Private

    private func makeHighlightsController(listener: QuranNavigator) -> (() -> UIViewController)? {
        #if QURAN_SYNC
            guard container.syncService != nil else {
                return nil
            }

            return { [container] in
                HighlightsBuilder(container: container, listener: listener).build()
            }
        #else
            return nil
        #endif
    }

    private func makeHighlightCollectionsUpdates() -> (() -> AsyncThrowingStream<[HighlightCollectionSnapshot], Error>)? {
        #if QURAN_SYNC
            guard let syncService = container.syncService else {
                return nil
            }

            return {
                HighlightCollection.updates(from: syncService)
            }
        #else
            return nil
        #endif
    }
}
