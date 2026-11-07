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

    /// `bottomBarsHeight` keeps the sheet's toasts above the presenter's bottom bars.
    public func build(
        verses: [AyahNumber],
        collections: [AyahBookmarkCollection],
        highlights: [AyahNumber: HighlightColor] = [:],
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
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
        let navigationController = navigationController(viewModel: viewModel, bottomBarsHeight: bottomBarsHeight)
        sheet = navigationController
        return navigationController
    }

    // MARK: Private

    private let container: AppDependencies

    private func navigationController(
        viewModel: BookmarkAyahsViewModel,
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
    ) -> UIViewController {
        let viewController = BookmarkAyahsViewController(viewModel: viewModel, bottomBarsHeight: bottomBarsHeight)
        let navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        return navigationController
    }
}
#endif
