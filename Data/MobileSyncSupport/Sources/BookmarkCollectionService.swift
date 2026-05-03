//
//  BookmarkCollectionService.swift
//
//
//  Created by Ahmed Nabil on 2026-04-22.
//

#if QURAN_SYNC
    import Foundation
    import MobileSync
    import QuranKit

    public struct BookmarkCollectionService {
        // MARK: Lifecycle

        public init(syncService: SyncService) {
            self.syncService = syncService
        }

        // MARK: Public

        public func createCollection(named name: String) async throws {
            try await syncService.createCollection(named: name)
        }

        @discardableResult
        public func addAyahBookmark(_ ayah: AyahNumber, toCollectionLocalId collectionLocalId: String) async throws -> Bookmark {
            let bookmark = try await syncService.addAyahBookmark(
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah)
            )
            try await addBookmark(bookmark, toCollectionLocalId: collectionLocalId)
            return bookmark
        }

        public func addBookmark(_ bookmark: Bookmark, toCollectionLocalId collectionLocalId: String) async throws {
            try await syncService.addBookmarkToCollection(
                collectionLocalId: collectionLocalId,
                bookmark: bookmark
            )
        }

        public func removeBookmark(_ bookmark: Bookmark, fromCollectionLocalId collectionLocalId: String) async throws {
            try await syncService.removeBookmarkFromCollection(
                collectionLocalId: collectionLocalId,
                bookmark: bookmark
            )
        }

        // MARK: Private

        private let syncService: SyncService
    }
#endif
