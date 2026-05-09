#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionsViewModel.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Foundation
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
            navigateToPage: @escaping (Page) -> Void
        ) {
            self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
            self.includedCollectionNames = includedCollectionNames
            self.excludedCollectionNames = excludedCollectionNames
            self.navigateToPage = navigateToPage
        }

        // MARK: Internal

        @Published var error: Error?
        @Published var editMode: EditMode = .inactive
        @Published var collections: [AyahBookmarkCollection] = []
        @Published var collapsedCollectionIDs: Set<String> = []

        static func sorted(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
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
            do {
                let sequence = ayahBookmarkCollectionService.collectionsSequence()
                for try await collections in sequence {
                    self.collections = Self.sorted(filtered(collections))
                    try await ensureHighlightCollections(collections)
                }
            } catch {
                self.error = error
            }
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
        private let navigateToPage: (Page) -> Void
        private var didEnsureHighlightCollections = false

        private static func highlightSortIndex(_ collection: AyahBookmarkCollection) -> Int? {
            guard let color = HighlightColor(collectionName: collection.collection.name) else {
                return nil
            }
            return HighlightColor.allCases.firstIndex(of: color)
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

        private func ensureHighlightCollections(_ collections: [AyahBookmarkCollection]) async throws {
            guard !didEnsureHighlightCollections, includedCollectionNames == nil else {
                return
            }
            didEnsureHighlightCollections = true
            try await HighlightBookmarkCollections.ensure(in: collections, using: ayahBookmarkCollectionService)
        }
    }
#endif
