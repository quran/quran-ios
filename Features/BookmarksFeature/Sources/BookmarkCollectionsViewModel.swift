#if QURAN_SYNC
//
//  BookmarkCollectionsViewModel.swift
//

import AuthenticationClient
import Combine
import Foundation
import QuranAnnotations
import SwiftUI
import UIKit
import VLogging

@MainActor
final class BookmarkCollectionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        authenticationClient: any AuthenticationClient,
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        collectionsBuilder: AyahBookmarkCollectionsBuilder,
        navigationController: UINavigationController
    ) {
        self.authenticationClient = authenticationClient
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.collectionsBuilder = collectionsBuilder
        self.navigationController = navigationController
        isSyncBannerDismissed = preferences.isSyncBannerDismissed
    }

    // MARK: Internal

    @Published var collections: [AyahBookmarkCollection] = []
    @Published var editMode: EditMode = .inactive
    @Published var error: Error?
    @Published var isAuthenticated = false
    @Published var isPresentingAddCollection = false
    @Published var isSyncBannerDismissed: Bool
    @Published var newCollectionName = ""

    var shouldShowSyncBanner: Bool {
        !isAuthenticated && !isSyncBannerDismissed
    }

    var oldPageBookmarksCollection: AyahBookmarkCollection? {
        collections.first {
            $0.collection.name == AyahBookmarkCollectionName.oldPageBookmarks
        }
    }

    static func sorted(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
        collections.sorted { lhs, rhs in
            switch (highlightSortIndex(lhs), highlightSortIndex(rhs)) {
            case let (.some(lhsIndex), .some(rhsIndex)):
                return lhsIndex < rhsIndex
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.collection.name.localizedCaseInsensitiveCompare(rhs.collection.name) == .orderedAscending
            }
        }
    }

    func start() async {
        async let observeCollections: Void = observeCollections()
        isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated
        await observeCollections
    }

    func loginToQuranCom() async {
        guard let navigationController else {
            return
        }

        do {
            try await authenticationClient.login(on: navigationController)
            isAuthenticated = true
        } catch {
            logger.error("Failed to login to Quran.com from bookmarks: \(error)")
            self.error = error
        }
    }

    func dismissSyncBanner() {
        isSyncBannerDismissed = true
        preferences.isSyncBannerDismissed = true
    }

    func presentAddCollection() {
        newCollectionName = ""
        isPresentingAddCollection = true
    }

    func createPendingCollection() async {
        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        do {
            try await ayahBookmarkCollectionService.createCollection(named: name)
        } catch {
            self.error = error
        }
    }

    func deleteCollection(_ collection: AyahBookmarkCollection) async {
        do {
            try await ayahBookmarkCollectionService.removeCollection(localId: collection.collection.localId)
        } catch {
            self.error = error
        }
    }

    func showCollection(_ collection: AyahBookmarkCollection) {
        navigationController?.pushViewController(
            collectionsBuilder.buildCollection(collection),
            animated: true
        )
    }

    // MARK: Private

    private let authenticationClient: any AuthenticationClient
    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let collectionsBuilder: AyahBookmarkCollectionsBuilder
    private let preferences = BookmarkCollectionsPreferences.shared
    private weak var navigationController: UINavigationController?

    private static func highlightSortIndex(_ collection: AyahBookmarkCollection) -> Int? {
        guard let color = HighlightColor(collectionName: collection.collection.name) else {
            return nil
        }
        return HighlightColor.sortedColors.firstIndex(of: color)
    }

    private func observeCollections() async {
        do {
            for try await collections in ayahBookmarkCollectionService.collectionsSequence() {
                self.collections = Self.sorted(collections)
            }
        } catch {
            self.error = error
        }
    }
}
#endif
