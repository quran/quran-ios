#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionService.swift
    //
    //  Created by Ahmed Nabil on 2026-05-06.
    //

    import MobileSync
    import QuranKit
    import ReadingService

    struct AyahBookmarkCollection {
        let collection: Collection_
        let bookmarks: [AyahCollectionBookmark]
    }

    struct AyahCollectionBookmark {
        let bookmark: CollectionAyahBookmark
        let ayah: AyahNumber
    }

    struct AyahBookmarkCollectionService {
        // MARK: Lifecycle

        init(readingPreferences: ReadingPreferences = .shared) {
            self.init(syncService: nil, readingPreferences: readingPreferences)
        }

        init(
            syncService: SyncService?,
            readingPreferences: ReadingPreferences = .shared
        ) {
            self.syncService = syncService
            self.readingPreferences = readingPreferences
        }

        // MARK: Internal

        func collectionsSequence() -> AsyncThrowingStream<[AyahBookmarkCollection], Error> {
            AsyncThrowingStream { continuation in
                let task = Task {
                    do {
                        let syncService = try requireSyncService()
                        for try await collections in syncService.collectionsWithBookmarksSequence() {
                            continuation.yield(self.collections(from: collections))
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }

        func createCollection(named name: String) async throws {
            let syncService = try requireSyncService()
            try await syncService.createCollection(named: name)
        }

        func removeCollection(localId: String) async throws {
            let syncService = try requireSyncService()
            try await syncService.removeCollection(localId: localId)
        }

        // TODO: Move this conversion to mobile-sync-spm once it supports deleting
        // collection bookmarks directly without converting to AyahBookmark first.
        func removeBookmarkFromCollection(_ bookmark: AyahCollectionBookmark) async throws {
            let syncService = try requireSyncService()
            try await syncService.removeBookmarkFromCollection(
                collectionLocalId: bookmark.bookmark.collectionLocalId,
                bookmark: AyahBookmark(
                    sura: bookmark.bookmark.sura,
                    ayah: bookmark.bookmark.ayah,
                    lastUpdated: bookmark.bookmark.lastUpdated,
                    localId: bookmark.bookmark.bookmarkLocalId
                )
            )
        }

        func collections(from collections: [CollectionWithAyahBookmarks]) -> [AyahBookmarkCollection] {
            collections.map { collection in
                AyahBookmarkCollection(
                    collection: collection.collection,
                    bookmarks: collection.bookmarks.compactMap(bookmark)
                )
            }
        }

        func page(for bookmark: AyahCollectionBookmark) -> Page {
            bookmark.ayah.page
        }

        // MARK: Private

        private let syncService: SyncService?
        private let readingPreferences: ReadingPreferences

        private func requireSyncService() throws -> SyncService {
            guard let syncService else {
                throw AyahBookmarkCollectionServiceError.missingSyncService
            }
            return syncService
        }

        private func bookmark(for bookmark: CollectionAyahBookmark) -> AyahCollectionBookmark? {
            guard let ayah = AyahNumber(
                quran: readingPreferences.reading.quran,
                sura: Int(bookmark.sura),
                ayah: Int(bookmark.ayah)
            ) else {
                return nil
            }
            return AyahCollectionBookmark(bookmark: bookmark, ayah: ayah)
        }
    }

    private enum AyahBookmarkCollectionServiceError: Error {
        case missingSyncService
    }
#endif
