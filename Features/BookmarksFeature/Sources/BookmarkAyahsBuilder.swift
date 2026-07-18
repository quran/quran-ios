//
//  BookmarkAyahsBuilder.swift
//

import AppDependencies
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

    #if QURAN_SYNC
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
    #else
    public func build(
        verses: [AyahNumber],
        notes: [QuranAnnotations.Note]
    ) -> UIViewController {
        let viewModel = BookmarkAyahsViewModel(
            verses: verses,
            notes: notes,
            noteService: container.noteService()
        )
        return navigationController(viewModel: viewModel)
    }
    #endif

    // MARK: Private

    private let container: AppDependencies

    private func navigationController(viewModel: BookmarkAyahsViewModel) -> UIViewController {
        let viewController = BookmarkAyahsViewController(viewModel: viewModel)
        let navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        return navigationController
    }
}
