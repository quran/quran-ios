#if QURAN_SYNC
//
//  BookmarkAyahsBuilder.swift
//

import AnnotationsService
import AppDependencies
import NoorUI
import QuranAnnotations
import QuranKit
import ReadingService
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
        let quran = ReadingPreferences.shared.reading.quran
        let viewModel = BookmarkAyahsViewModel(
            verses: verses,
            collections: collections,
            highlights: highlights,
            ayahBookmarkCollectionService: container.ayahBookmarkCollectionService(quran: quran),
            ayahHighlightService: container.ayahHighlightService(quran: quran)
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
