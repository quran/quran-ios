#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionsViewModel.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Foundation
    import Localization
    import QuranAnnotations
    import QuranKit
    import SwiftUI
    import VLogging

    @MainActor
    final class AyahBookmarkCollectionsViewModel: ObservableObject {
        // MARK: Lifecycle

        init(
            ayahBookmarkCollectionService: AyahBookmarkCollectionService,
            includedCollectionNames: Set<String>? = nil,
            excludedCollectionNames: Set<String> = [],
            prepareCollections: @escaping ([AyahBookmarkCollection]) async throws -> Void = { _ in },
            navigateToPage: @escaping (Page) -> Void
        ) {
            self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
            self.includedCollectionNames = includedCollectionNames
            self.excludedCollectionNames = excludedCollectionNames
            self.prepareCollections = prepareCollections
            self.navigateToPage = navigateToPage
        }

        // MARK: Internal

        @Published var error: Error?
        @Published var editMode: EditMode = .inactive
        @Published var collections: [AyahBookmarkCollection] = []
        @Published var collapsedCollectionIDs: Set<String> = []

        nonisolated static func sorted(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
            collections.sorted { lhs, rhs in
                switch (highlightSortIndex(lhs), highlightSortIndex(rhs)) {
                case let (lhsIndex?, rhsIndex?):
                    return lhsIndex < rhsIndex
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.collection.name.localizedCaseInsensitiveCompare(rhs.collection.name) == .orderedAscending
                }
            }
        }

        func start() async {
            async let collections: Void = observeCollections()
            async let bookmarks: Void = observeBookmarks()
            _ = await [collections, bookmarks]
        }

        func isCollectionExpanded(_ collection: AyahBookmarkCollection) -> Bool {
            !collapsedCollectionIDs.contains(collection.collection.localId)
        }

        func setCollection(_ collection: AyahBookmarkCollection, expanded: Bool) {
            let id = collection.collection.localId
            if expanded {
                collapsedCollectionIDs.remove(id)
            } else {
                collapsedCollectionIDs.insert(id)
            }
        }

        func navigateTo(_ bookmark: AyahCollectionBookmark) {
            logger.info("Bookmarks: select collection bookmark at \(bookmark.ayah)")
            navigateToPage(bookmark.ayah.page)
        }

        func createCollection(name: String) async {
            do {
                try await ayahBookmarkCollectionService.createCollection(named: name)
            } catch {
                self.error = error
            }
        }

        func deleteCollection(_ collection: AyahBookmarkCollection) async {
            guard !collection.isLocalOnly else {
                return
            }

            do {
                try await ayahBookmarkCollectionService.removeCollection(localId: collection.collection.localId)
            } catch {
                self.error = error
            }
        }

        func deleteBookmark(_ bookmark: AyahCollectionBookmark) async {
            do {
                try await ayahBookmarkCollectionService.removeBookmarkFromCollection(bookmark)
            } catch {
                self.error = error
            }
        }

        // MARK: Private

        private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
        private let includedCollectionNames: Set<String>?
        private let excludedCollectionNames: Set<String>
        private let prepareCollections: ([AyahBookmarkCollection]) async throws -> Void
        private let navigateToPage: (Page) -> Void
        private var didPrepareCollections = false
        private var syncedCollections: [AyahBookmarkCollection] = []
        private var directBookmarks: [AyahCollectionBookmark] = []

        private nonisolated static func highlightSortIndex(_ collection: AyahBookmarkCollection) -> Int? {
            guard let color = HighlightColor(collectionName: collection.collection.name) else {
                return nil
            }
            return HighlightColor.allCases.firstIndex(of: color)
        }

        private func observeCollections() async {
            do {
                let sequence = ayahBookmarkCollectionService.collectionsSequence()
                for try await collections in sequence {
                    syncedCollections = collections
                    refreshCollections()
                    try await prepareCollectionsIfNeeded(collections)
                }
            } catch {
                self.error = error
            }
        }

        private func observeBookmarks() async {
            do {
                let sequence = ayahBookmarkCollectionService.bookmarksSequence()
                for try await bookmarks in sequence {
                    directBookmarks = bookmarks
                    refreshCollections()
                }
            } catch {
                self.error = error
            }
        }

        private func refreshCollections() {
            collections = Self.sorted(filtered(syncedCollections + [favouritesCollection()]))
        }

        private func favouritesCollection() -> AyahBookmarkCollection {
            FavouritesBookmarkCollection.make(
                name: l("bookmarks.collections.favourites"),
                bookmarks: directBookmarks,
                collections: syncedCollections
            )
        }

        private func filtered(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
            collections.filter { collection in
                let name = collection.collection.name
                if let includedCollectionNames {
                    return includedCollectionNames.contains(name)
                }
                return !excludedCollectionNames.contains(name)
            }
        }

        private func prepareCollectionsIfNeeded(_ collections: [AyahBookmarkCollection]) async throws {
            guard !didPrepareCollections else {
                return
            }
            didPrepareCollections = true
            try await prepareCollections(collections)
        }
    }
#endif
