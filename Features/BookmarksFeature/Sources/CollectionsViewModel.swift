#if QURAN_SYNC
    //
    //  CollectionsViewModel.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Foundation
    import MobileSync
    import QuranKit
    import ReadingService
    import SwiftUI
    import VLogging

    @MainActor
    final class CollectionsViewModel: ObservableObject {
        init(syncService: SyncService, navigateToPage: @escaping (Page) -> Void) {
            self.syncService = syncService
            self.navigateToPage = navigateToPage
        }

        @Published var error: Error?
        @Published var collections: [CollectionWithAyahBookmarks] = []
        @Published var collapsedCollectionIDs: Set<String> = []

        func start() async {
            do {
                for try await collections in syncService.collectionsWithBookmarksSequence() {
                    self.collections = collections.sorted {
                        $0.collection.name.localizedCaseInsensitiveCompare($1.collection.name) == .orderedAscending
                    }
                }
            } catch {
                self.error = error
            }
        }

        func isCollectionExpanded(_ collection: CollectionWithAyahBookmarks) -> Bool {
            !collapsedCollectionIDs.contains(collection.collection.localId)
        }

        func setCollection(_ collection: CollectionWithAyahBookmarks, expanded: Bool) {
            let id = collection.collection.localId
            if expanded {
                collapsedCollectionIDs.remove(id)
            } else {
                collapsedCollectionIDs.insert(id)
            }
        }

        func toggleCollection(_ collection: CollectionWithAyahBookmarks) {
            setCollection(collection, expanded: !isCollectionExpanded(collection))
        }

        func navigateTo(_ bookmark: CollectionAyahBookmark) {
            logger.info("Bookmarks: select collection bookmark at \(bookmark.sura):\(bookmark.ayah)")
            guard let ayah = AyahNumber(quran: readingPreferences.reading.quran, sura: Int(bookmark.sura), ayah: Int(bookmark.ayah)) else {
                return
            }
            navigateToPage(ayah.page)
        }

        func createCollection(name: String) async {
            do {
                try await syncService.createCollection(named: name)
            } catch {
                self.error = error
            }
        }

        func deleteItem(_ collection: CollectionWithAyahBookmarks) async {
            do {
                try await syncService.removeCollection(localId: collection.collection.localId)
            } catch {
                self.error = error
            }
        }

        private let syncService: SyncService
        private let navigateToPage: (Page) -> Void
        private let readingPreferences = ReadingPreferences.shared
    }
#endif
