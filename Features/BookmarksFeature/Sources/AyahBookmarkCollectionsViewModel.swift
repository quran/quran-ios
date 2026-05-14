#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionsViewModel.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Foundation
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

        func start() async {
            do {
                let sequence = ayahBookmarkCollectionService.collectionsSequence()
                for try await collections in sequence {
                    self.collections = filtered(collections).sorted {
                        $0.collection.name.localizedCaseInsensitiveCompare($1.collection.name) == .orderedAscending
                    }
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

        private func filtered(_ collections: [AyahBookmarkCollection]) -> [AyahBookmarkCollection] {
            collections.filter { collection in
                let name = collection.collection.name
                if let includedCollectionNames {
                    return includedCollectionNames.contains(name)
                }
                return !excludedCollectionNames.contains(name)
            }
        }
    }
#endif
