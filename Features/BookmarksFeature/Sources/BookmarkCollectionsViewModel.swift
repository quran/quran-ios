#if QURAN_SYNC
//
//  BookmarkCollectionsViewModel.swift
//

import Analytics
import AnnotationsService
import AuthenticationClient
import Combine
import FeaturesSupport
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
        analytics: AnalyticsLibrary,
        authenticationClient: any AuthenticationClient,
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        ayahHighlightService: MobileSyncAyahHighlightService,
        readingBookmarkService: MobileSyncReadingBookmarkService,
        ayahSetBuilder: AyahSetBuilder,
        navigationController: UINavigationController,
        navigateToPage: @escaping (Page) -> Void,
        navigateToAyah: @escaping (AyahNumber) -> Void
    ) {
        self.analytics = analytics
        self.authenticationClient = authenticationClient
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.ayahHighlightService = ayahHighlightService
        self.readingBookmarkService = readingBookmarkService
        self.ayahSetBuilder = ayahSetBuilder
        self.navigationController = navigationController
        self.navigateToPage = navigateToPage
        self.navigateToAyah = navigateToAyah
        isSyncBannerDismissed = preferences.isCollectionsSyncBannerDismissed
    }

    // MARK: Internal

    @Published var collections: [AyahBookmarkCollection] = []
    @Published var highlights: [AyahNumber: HighlightColor] = [:]
    @Published var collectionPendingDeletion: AyahBookmarkCollection?
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
            lhs.collection.name.localizedCaseInsensitiveCompare(rhs.collection.name) == .orderedAscending
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
        async let observeHighlights: Void = observeHighlights()
        async let observeReadingBookmark: Void = observeReadingBookmark()
        isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated
        logger.info("Quran Sync: restored authentication from Bookmarks. Authenticated: \(isAuthenticated)")
        _ = await (observeCollections, observeHighlights, observeReadingBookmark)
    }

    func loginToQuranCom() async {
        guard let navigationController else {
            return
        }

        analytics.quranSyncSignIn(from: .bookmarks)
        logger.info("Quran Sync: starting sign in from Bookmarks")
        do {
            try await authenticationClient.login(on: navigationController)
            isAuthenticated = await authenticationClient.authenticationState == .authenticated
            logger.info("Quran Sync: sign in completed from Bookmarks. Authenticated: \(isAuthenticated)")
        } catch AuthenticationClientError.cancelled {
            logger.info("Quran Sync: sign in cancelled from Bookmarks")
            return
        } catch {
            logger.error("Failed to login to Quran.com from bookmarks: \(error)")
            self.error = error
        }
    }

    func dismissSyncBanner() {
        analytics.quranSyncSignInBannerDismissed(from: .bookmarks)
        logger.info("Quran Sync: sign-in banner dismissed from Bookmarks")
        isSyncBannerDismissed = true
        preferences.isCollectionsSyncBannerDismissed = true
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
            logger.error("Quran Sync: failed to create bookmark collection: \(error)")
            self.error = error
        }
    }

    func requestDeleteCollection(_ collection: AyahBookmarkCollection) async {
        guard collection.kind.canDelete else {
            return
        }
        guard !collection.bookmarks.isEmpty else {
            await deleteCollection(collection)
            return
        }
        collectionPendingDeletion = collection
    }

    func deleteCollection(_ collection: AyahBookmarkCollection) async {
        guard collection.kind.canDelete else {
            return
        }
        do {
            try await ayahBookmarkCollectionService.removeCollection(id: collection.collection.id)
        } catch {
            logger.error("Quran Sync: failed to remove bookmark collection: \(error)")
            self.error = error
        }
    }

    func showCollection(_ collection: AyahBookmarkCollection) {
        navigationController?.pushViewController(
            ayahSetBuilder.buildCollection(
                collection,
                collectionDeleted: { [weak navigationController] in
                    navigationController?.popViewController(animated: true)
                }
            ),
            animated: true
        )
    }

    func showHighlights(_ color: HighlightColor) {
        let ayahs = highlights.compactMap { ayah, highlightColor in
            highlightColor == color ? ayah : nil
        }
        navigationController?.pushViewController(
            ayahSetBuilder.buildHighlights(color: color, ayahs: ayahs),
            animated: true
        )
    }

    func navigateTo(_ readingBookmark: ReadingPositionBookmark) {
        switch readingBookmark.location {
        case .ayah(let ayahNumber):
            navigateToAyah(ayahNumber)
        case .page(let page):
            navigateToPage(page)
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let authenticationClient: any AuthenticationClient
    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let ayahHighlightService: MobileSyncAyahHighlightService
    private let readingBookmarkService: MobileSyncReadingBookmarkService
    private let ayahSetBuilder: AyahSetBuilder
    private let navigateToPage: (Page) -> Void
    private let navigateToAyah: (AyahNumber) -> Void
    private let preferences = AuthenticationPreferences.shared
    private let readingPreferences = ReadingPreferences.shared
    private weak var navigationController: UINavigationController?

    private static func displayedCollectionSortIndex(_ collection: AyahBookmarkCollection) -> Int {
        switch collection.kind {
        case .defaultBookmarks:
            0
        case .oldPageBookmarks:
            1
        case .user:
            2
        }
    }

    private func observeHighlights() async {
        do {
            for try await highlights in ayahHighlightService.highlightsSequence() {
                self.highlights = highlights
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe highlights in Bookmarks: \(error)")
            self.error = error
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
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe collections in Bookmarks: \(error)")
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
                    logger.error("Quran Sync: failed to observe reading bookmark in Bookmarks: \(error)")
                    self?.error = error
                }
            }
        }
    }
}
#endif
