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
import Localization
import QuranKit
import UIKit

@MainActor
public struct BookmarksBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        #if QURAN_SYNC
        return BookmarkCollectionsLandingBuilder(container: container).build(withListener: listener)
        #else
        let service = PageBookmarkService(persistence: container.pageBookmarkPersistence)
        let viewModel = BookmarksViewModel(
            analytics: container.analytics,
            service: service,
            navigateTo: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        return BookmarksViewController(viewModel: viewModel)
        #endif
    }

    // MARK: Internal

    let container: AppDependencies
}
