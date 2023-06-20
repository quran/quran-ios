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
        let interactor = BookmarksInteractor(
            analytics: container.analytics,
            service: service
        )
        interactor.listener = listener
        let viewController = BookmarksTableViewController(interactor: interactor)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
