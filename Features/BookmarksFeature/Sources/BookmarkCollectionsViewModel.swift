#if QURAN_SYNC
//
//  BookmarkCollectionsViewModel.swift
//

import AnnotationsService
import AuthenticationClient
import Combine
import FeaturesSupport
import Foundation
import MobileSync
import NoorUI
import QuranAnnotations
import QuranKit
import ReadingService
import SwiftUI
import UIKit
import Utilities
import VLogging

@MainActor
final class BookmarkCollectionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        authenticationClient: any AuthenticationClient,
        quranDataService: MobileSyncDataService,
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        ayahHighlightService: MobileSyncAyahHighlightService,
        readingBookmarkService: MobileSyncReadingBookmarkService,
        ayahSetBuilder: AyahSetBuilder,
        navigationController: UINavigationController,
        navigateToPage: @escaping (Page) -> Void,
        navigateToAyah: @escaping (AyahNumber) -> Void
    ) {
        self.authenticationClient = authenticationClient
        self.quranDataService = quranDataService
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.ayahHighlightService = ayahHighlightService
        self.readingBookmarkService = readingBookmarkService
        self.ayahSetBuilder = ayahSetBuilder
        self.navigationController = navigationController
        self.navigateToPage = navigateToPage
        self.navigateToAyah = navigateToAyah
        // Follow sign-in and sign-out elsewhere, such as in Settings.
        authenticationClient.authenticationStateChanges
            .map { $0 == .authenticated }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
    }

    // MARK: Internal

    @Published var collections: [AyahBookmarkCollection] = []
    @Published var highlights: [AyahNumber: HighlightColor] = [:]
    @Published var collectionPendingDeletion: AyahBookmarkCollection?
    /// The collection whose ayahs the Delete All confirmation is for.
    @Published var collectionPendingRemoveAll: AyahBookmarkCollection?
    /// The highlight color the Delete All confirmation is for.
    @Published var highlightColorPendingRemoveAll: HighlightColor?
    @Published var editMode: EditMode = .inactive
    @Published var error: Error?
    @Published var isAuthenticated = false
    @Published var nameAlert: CollectionNameAlert = .hidden
    @Published var newCollectionName = ""
    @Published var renameAlert: CollectionNameAlert = .hidden
    @Published var renamedCollectionName = ""
    @Published var readingBookmarks: [PlacedReadingBookmark] = []
    /// The reading bookmark the rename alert is for, or `nil` when it's hidden.
    @Published var renamingReadingBookmark: ReadingBookmarkSlot?
    @Published var readingBookmarkName = ""
    /// The collections and colors whose Delete All is running, so it can't start twice.
    @Published private(set) var collectionIDsRemovingAllAyahs: Set<String> = []
    @Published private(set) var colorsRemovingAllHighlights: Set<HighlightColor> = []

    /// Pull-to-refresh, when signed in. Not tied to edit mode: toggling it rebuilds the list.
    var canRefresh: Bool {
        isAuthenticated
    }

    var oldPageBookmarksCollection: AyahBookmarkCollection? {
        collections.first {
            $0.kind == .oldPageBookmarks
        }
    }

    var displayedCollections: [AyahBookmarkCollection] {
        Self.displayedCollections(from: collections)
    }

    var deletableCollections: [AyahBookmarkCollection] {
        Self.deletableCollections(from: collections)
    }

    var hasDeletableItems: Bool {
        !deletableCollections.isEmpty || !readingBookmarks.isEmpty
    }

    /// Long-press menus are off in Edit mode, which has its own delete.
    var isItemMenuEnabled: Bool {
        !editMode.isEditing
    }

    /// Read-only collections can't be deleted, so their menu empties them instead, unless that's already running.
    func canRemoveAllAyahs(from collection: AyahBookmarkCollection) -> Bool {
        collection.canRemoveAllAyahs && !collectionIDsRemovingAllAyahs.contains(collection.id)
    }

    func canRemoveAllHighlights(_ color: HighlightColor) -> Bool {
        !colorsRemovingAllHighlights.contains(color)
    }

    static func sorted(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
        collections.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    static func deletableCollections(from collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
        let deletableCollections = collections.filter(\.canDelete)
        let oldPageBookmarks = deletableCollections.filter { $0.kind == .oldPageBookmarks }
        let remainingCollections = deletableCollections.filter { $0.kind != .oldPageBookmarks }
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

    /// Waits for a sync; failures are only logged, as Settings › Sync shows them.
    /// - Returns: `nil` when signed out or it stopped waiting.
    @discardableResult
    func refresh() async -> MobileSyncNowResult? {
        guard isAuthenticated else {
            return nil
        }
        logger.info("Quran Sync: userRequestedRefresh from Bookmarks")
        do {
            let result = try await quranDataService.syncNow()
            logger.info("Quran Sync: refresh from Bookmarks finished. \(result)")
            return result
        } catch is CancellationError {
            logger.info("Quran Sync: stopped waiting for the refresh from Bookmarks; the sync goes on")
        } catch {
            logger.error("Quran Sync: refresh from Bookmarks failed: \(error)")
        }
        return nil
    }

    func presentAddCollection() {
        newCollectionName = ""
        nameAlert = .editing
    }

    func createPendingCollection() async {
        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        do {
            try await ayahBookmarkCollectionService.createCollection(named: name)
            nameAlert = .hidden
        } catch {
            if let nameError = CollectionNameError(error) {
                logger.info("Quran Sync: bookmark collection name rejected. \(nameError.logDescription)")
                nameAlert = .rejected(nameError)
            } else {
                logger.error("Quran Sync: failed to create bookmark collection: \(error)")
                self.error = error
            }
        }
    }

    func requestDeleteCollection(_ collection: AyahBookmarkCollection) async {
        guard collection.canDelete else {
            return
        }
        guard !collection.bookmarks.isEmpty else {
            await deleteCollection(collection)
            return
        }
        collectionPendingDeletion = collection
    }

    func deleteCollection(_ collection: AyahBookmarkCollection) async {
        guard collection.canDelete else {
            return
        }
        do {
            try await ayahBookmarkCollectionService.removeCollection(id: collection.id)
        } catch {
            logger.error("Quran Sync: failed to remove bookmark collection: \(error)")
            self.error = error
        }
    }

    func presentRenameCollection(_ collection: AyahBookmarkCollection) {
        guard collection.canRename else {
            return
        }
        renamingCollection = collection
        renamedCollectionName = collection.displayName
        renameAlert = .editing
    }

    func renamePendingCollection() async {
        guard let collection = renamingCollection else {
            return
        }
        let name = renamedCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        // The field starts with the displayed name, which is localized for Old Page Bookmarks: writing it back
        // unchanged would turn that collection into a user collection.
        guard name != collection.displayName else {
            renameAlert = .hidden
            renamingCollection = nil
            return
        }

        do {
            try await ayahBookmarkCollectionService.renameCollection(id: collection.id, to: name)
            renameAlert = .hidden
            renamingCollection = nil
        } catch {
            if let nameError = CollectionNameError(error) {
                logger.info("Quran Sync: bookmark collection name rejected. \(nameError.logDescription)")
                renameAlert = .rejected(nameError)
            } else {
                logger.error("Quran Sync: failed to rename bookmark collection: \(error)")
                self.error = error
            }
        }
    }

    func requestRemoveAllAyahs(from collection: AyahBookmarkCollection) {
        collectionPendingRemoveAll = collection
    }

    /// Removes the collection's ayahs but keeps the collection.
    func removeAllAyahs(from collection: AyahBookmarkCollection) async {
        guard collectionIDsRemovingAllAyahs.insert(collection.id).inserted else {
            return
        }
        defer { collectionIDsRemovingAllAyahs.remove(collection.id) }
        logger.info("Quran Sync: remove all ayahs from bookmark collection")
        do {
            try await ayahBookmarkCollectionService.removeAllAyahs(fromCollectionWithID: collection.id)
        } catch {
            logger.error("Quran Sync: failed to remove all ayahs from bookmark collection: \(error)")
            self.error = error
        }
    }

    func requestRemoveAllHighlights(_ color: HighlightColor) {
        highlightColorPendingRemoveAll = color
    }

    func removeAllHighlights(_ color: HighlightColor) async {
        guard colorsRemovingAllHighlights.insert(color).inserted else {
            return
        }
        defer { colorsRemovingAllHighlights.remove(color) }
        logger.info("Quran Sync: remove all \(color) highlights")
        do {
            try await ayahHighlightService.removeAllHighlights(color)
        } catch {
            logger.error("Quran Sync: failed to remove all highlights: \(error)")
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
        navigationController?.pushViewController(
            ayahSetBuilder.buildHighlights(color: color, ayahs: ayahs(highlightedIn: color)),
            animated: true
        )
    }

    func deleteReadingBookmark(_ bookmark: PlacedReadingBookmark) async -> Toast? {
        do {
            try await readingBookmarkService.clearReadingBookmark(in: bookmark.slot)
        } catch {
            logger.error("Quran Sync: failed to clear reading bookmark from Bookmarks: \(error)")
            self.error = error
            return nil
        }
        // The toast can outlive this screen, so Undo keeps the view model alive until it restores.
        return ReadingBookmarkUndoToast.removed(bookmark) {
            Task { @MainActor in
                await self.restoreReadingBookmark(bookmark)
            }
        }
    }

    func presentRenameReadingBookmark(_ bookmark: PlacedReadingBookmark) {
        readingBookmarkName = bookmark.name ?? ""
        renamingReadingBookmark = bookmark.slot
    }

    /// Renames the reading bookmark in `slot`; an empty name clears it, so the bookmark goes by its color.
    func renameReadingBookmark(in slot: ReadingBookmarkSlot) async {
        let name = readingBookmarkName.trimmingCharacters(in: .whitespacesAndNewlines)
        // The bookmark can be cleared while the alert is open.
        guard readingBookmarks.contains(where: { $0.slot == slot }) else {
            return
        }
        do {
            try await readingBookmarkService.renameReadingBookmark(
                in: slot,
                name: name.isEmpty ? nil : name,
                quran: readingPreferences.reading.quran
            )
        } catch {
            logger.error("Quran Sync: failed to rename reading bookmark from Bookmarks: \(error)")
            self.error = error
        }
    }

    func navigateTo(_ readingBookmark: PlacedReadingBookmark) {
        switch readingBookmark.placement {
        case .ayah(let ayahNumber):
            navigateToAyah(ayahNumber)
        case .page(let page):
            navigateToPage(page)
        }
    }

    // MARK: Private

    private let authenticationClient: any AuthenticationClient
    private let quranDataService: MobileSyncDataService
    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let ayahHighlightService: MobileSyncAyahHighlightService
    private let readingBookmarkService: MobileSyncReadingBookmarkService
    private let ayahSetBuilder: AyahSetBuilder
    private let navigateToPage: (Page) -> Void
    private let navigateToAyah: (AyahNumber) -> Void
    private let readingPreferences = ReadingPreferences.shared
    private weak var navigationController: UINavigationController?
    /// The collection the rename alert is for.
    private var renamingCollection: AyahBookmarkCollection?

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

    private func ayahs(highlightedIn color: HighlightColor) -> [AyahNumber] {
        highlights.compactMap { ayah, highlightColor in
            highlightColor == color ? ayah : nil
        }
    }

    private func exitEditModeIfNothingIsDeletable() {
        if !hasDeletableItems {
            editMode = .inactive
        }
    }

    private func restoreReadingBookmark(_ bookmark: PlacedReadingBookmark) async {
        do {
            try await readingBookmarkService.addReadingBookmark(at: bookmark.placement, slot: bookmark.slot)
        } catch {
            logger.error("Quran Sync: failed to restore reading bookmark from Bookmarks: \(error)")
            self.error = error
        }
    }

    private func observeHighlights() async {
        let highlightsSequence = readingPreferences.readings().flatMapLatest { [ayahHighlightService] reading in
            ayahHighlightService.highlightsSequence(quran: reading.quran)
        }
        do {
            for try await highlights in highlightsSequence {
                self.highlights = highlights
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe highlights in Bookmarks: \(error)")
            self.error = error
        }
    }

    private func observeCollections() async {
        let collectionsSequence = readingPreferences.readings().flatMapLatest { [ayahBookmarkCollectionService] reading in
            ayahBookmarkCollectionService.collectionsSequence(quran: reading.quran)
        }
        do {
            for try await collections in collectionsSequence {
                let collections = Self.sorted(collections)
                self.collections = collections
                exitEditModeIfNothingIsDeletable()
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe collections in Bookmarks: \(error)")
            self.error = error
        }
    }

    private func observeReadingBookmark() async {
        let bookmarksSequence = readingPreferences.readings().flatMapLatest { [readingBookmarkService] reading in
            readingBookmarkService.placedReadingBookmarksSequence(quran: reading.quran)
        }
        do {
            for try await bookmarks in bookmarksSequence {
                readingBookmarks = PlacedReadingBookmark.sortedByDate(bookmarks)
                exitEditModeIfNothingIsDeletable()
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe reading bookmark in Bookmarks: \(error)")
            self.error = error
        }
    }
}
#endif
