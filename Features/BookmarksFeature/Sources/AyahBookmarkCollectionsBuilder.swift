#if QURAN_SYNC
//
//  AyahBookmarkCollectionsBuilder.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import Localization
import QuranKit
import UIKit

@MainActor
struct AyahBookmarkCollectionsBuilder {
    init(
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        includedCollectionNames: Set<String>? = nil,
        navigateToPage: @escaping (Page) -> Void,
        title: String = l("bookmarks.collections"),
        allowsCollectionManagement: Bool = true,
        allowsBookmarkDeletion: Bool = true
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.includedCollectionNames = includedCollectionNames
        self.navigateToPage = navigateToPage
        self.title = title
        self.allowsCollectionManagement = allowsCollectionManagement
        self.allowsBookmarkDeletion = allowsBookmarkDeletion
    }

    func build() -> UIViewController {
        let viewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: ayahBookmarkCollectionService,
            includedCollectionNames: includedCollectionNames,
            excludedCollectionNames: includedCollectionNames == nil ? [Self.oldPageBookmarksCollectionName] : [],
            navigateToPage: navigateToPage
        )
        return AyahBookmarkCollectionsViewController(
            viewModel: viewModel,
            title: title,
            allowsCollectionManagement: allowsCollectionManagement,
            allowsBookmarkDeletion: allowsBookmarkDeletion
        )
    }

    func buildOldPageBookmarks() -> UIViewController {
        let viewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: ayahBookmarkCollectionService,
            includedCollectionNames: [Self.oldPageBookmarksCollectionName],
            navigateToPage: navigateToPage
        )
        return AyahBookmarkCollectionsViewController(
            viewModel: viewModel,
            title: l("bookmarks.old-page-bookmarks"),
            allowsCollectionManagement: false,
            allowsBookmarkDeletion: false
        )
    }

    private static let oldPageBookmarksCollectionName = "Old Page Bookmarks"

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let includedCollectionNames: Set<String>?
    private let navigateToPage: (Page) -> Void
    private let title: String
    private let allowsCollectionManagement: Bool
    private let allowsBookmarkDeletion: Bool
}
#endif
