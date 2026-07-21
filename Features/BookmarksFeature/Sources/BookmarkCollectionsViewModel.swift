#if QURAN_SYNC
//
//  BookmarkCollectionsViewModel.swift
//

import AnnotationsService
import AuthenticationClient
import Combine
import Foundation
import QuranAnnotations
import QuranKit
import ReadingService
import SwiftUI
import UIKit
import VLogging

@MainActor
final class BookmarkCollectionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        authenticationClient: any AuthenticationClient,
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        readingBookmarkService: MobileSyncReadingBookmarkService,
        collectionsBuilder: AyahBookmarkCollectionsBuilder,
        navigationController: UINavigationController,
        navigateToPage: @escaping (Page, AyahNumber?) -> Void
    ) {
        self.authenticationClient = authenticationClient
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.readingBookmarkService = readingBookmarkService
        self.collectionsBuilder = collectionsBuilder
        self.navigationController = navigationController
        self.navigateToPage = navigateToPage
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
    @Published var readingBookmark: ReadingPositionBookmark?

    var shouldShowSyncBanner: Bool {
        !isAuthenticated && !isSyncBannerDismissed
    }

    var oldPageBookmarksCollection: AyahBookmarkCollection? {
        collections.first {
            $0.kind.isOldPageBookmarks
        }
    }

    var displayedCollections: [AyahBookmarkCollection] {
        Self.displayedCollections(from: collections)
    }

    var deletableCollections: [AyahBookmarkCollection] {
        Self.deletableCollections(from: collections)
    }

    var hasDeletableCollections: Bool {
        !deletableCollections.isEmpty
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

    static func deletableCollections(from collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
        let deletableCollections = collections.filter(\.kind.canDelete)
        let oldPageBookmarks = deletableCollections.filter(\.kind.isOldPageBookmarks)
        let remainingCollections = deletableCollections.filter { !$0.kind.isOldPageBookmarks }
        return oldPageBookmarks + remainingCollections
    }

    static func displayedCollections(from collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
        collections
            .filter { $0.kind.highlightColor == nil }
            .sorted { lhs, rhs in
                let lhsIndex = displayedCollectionSortIndex(lhs)
                let rhsIndex = displayedCollectionSortIndex(rhs)
                if lhsIndex != rhsIndex {
                    return lhsIndex < rhsIndex
                }
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
    }

    func start() async {
        async let observeCollections: Void = observeCollections()
        async let observeReadingBookmark: Void = observeReadingBookmark()
        isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated
        _ = await (observeCollections, observeReadingBookmark)
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
        guard collection.kind.canDelete else {
            return
        }
        do {
            try await ayahBookmarkCollectionService.removeCollection(id: collection.collection.id)
        } catch {
            self.error = error
        }
    }

    func showCollection(_ collection: AyahBookmarkCollection) {
        navigationController?.pushViewController(
            collectionsBuilder.buildCollection(
                collection,
                collectionDeleted: { [weak navigationController] in
                    navigationController?.popViewController(animated: true)
                }
            ),
            animated: true
        )
    }

    func navigateTo(_ readingBookmark: ReadingPositionBookmark) {
        switch readingBookmark.location {
        case .ayah(let ayahNumber):
            navigateToPage(ayahNumber.page, ayahNumber)
        case .page(let page):
            navigateToPage(page, nil)
        }
    }

    // MARK: Private

    private let authenticationClient: any AuthenticationClient
    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let readingBookmarkService: MobileSyncReadingBookmarkService
    private let collectionsBuilder: AyahBookmarkCollectionsBuilder
    private let navigateToPage: (Page, AyahNumber?) -> Void
    private let preferences = BookmarkCollectionsPreferences.shared
    private let readingPreferences = ReadingPreferences.shared
    private weak var navigationController: UINavigationController?

    private static func highlightSortIndex(_ collection: AyahBookmarkCollection) -> Int? {
        guard let color = collection.kind.highlightColor else {
            return nil
        }
        return HighlightColor.alphabeticallySortedColors.firstIndex(of: color)
    }

    private static func displayedCollectionSortIndex(_ collection: AyahBookmarkCollection) -> Int {
        switch collection.kind {
        case .defaultBookmarks:
            0
        case .oldPageBookmarks:
            1
        case .user:
            2
        case .colored:
            3
        }
    }

    private func observeCollections() async {
        do {
            for try await collections in ayahBookmarkCollectionService.collectionsSequence() {
                let collections = Self.sorted(collections)
                self.collections = collections
                if Self.deletableCollections(from: collections).isEmpty {
                    editMode = .inactive
                }
            }
        } catch {
            self.error = error
        }
    }

    private func observeReadingBookmark() async {
        let readings = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .values()
        var observationTask: Task<Void, Never>?
        defer { observationTask?.cancel() }

        for await reading in readings {
            observationTask?.cancel()
            let sequence = readingBookmarkService.readingBookmarkSequence(quran: reading.quran)
            observationTask = Task { [weak self] in
                do {
                    for try await bookmark in sequence {
                        guard !Task.isCancelled else { return }
                        self?.readingBookmark = bookmark
                    }
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled else { return }
                    self?.error = error
                }
            }
        }
    }
}
#endif
