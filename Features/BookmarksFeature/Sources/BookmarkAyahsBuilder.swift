#if QURAN_SYNC
//
//  BookmarkAyahsBuilder.swift
//

import AnnotationsService
import AppDependencies
import FeaturesSupport
import NoorUI
import QuranAnnotations
import QuranKit
import UIKit

@MainActor
public struct BookmarkAyahsBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(
        verses: [AyahNumber],
        collections: [AyahBookmarkCollection],
        highlights: [AyahNumber: HighlightColor] = [:]
    ) -> UIViewController {
        weak var sheet: UIViewController?
        let viewModel = BookmarkAyahsViewModel(
            verses: verses,
            collections: collections,
            highlights: highlights,
            analytics: container.analytics,
            ayahBookmarkCollectionService: container.ayahBookmarkCollectionService(),
            ayahHighlightService: container.ayahHighlightService(),
            signInNudge: SyncSignInNudge(
                authenticationClient: container.authenticationClient,
                analytics: container.analytics,
                // The sheet can close before Sign In, so fall back to the screens under it.
                signInViewControllers: {
                    sheet.map { Array(sequence(first: $0, next: \.presentingViewController)) } ?? []
                }
            )
        )
        let navigationController = navigationController(viewModel: viewModel)
        sheet = navigationController
        return navigationController
    }

    // MARK: Private

    private let container: AppDependencies

    private func navigationController(viewModel: BookmarkAyahsViewModel) -> UIViewController {
        let viewController = BookmarkAyahsViewController(viewModel: viewModel)
        let navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        return navigationController
    }
}
#endif
