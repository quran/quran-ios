#if QURAN_SYNC
//
//  BookmarkAyahsBuilder.swift
//

import AppDependencies
import NoorUI
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
        collections: [AyahBookmarkCollection]
    ) -> UIViewController {
        let viewModel = BookmarkAyahsViewModel(
            verses: verses,
            collections: collections,
            ayahBookmarkCollectionService: AyahBookmarkCollectionService(
                quranDataService: container.quranDataService
            )
        )
        return navigationController(viewModel: viewModel)
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
