#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionService.swift
    //
    //  Created by Ahmed Nabil on 2026-05-06.
    //

    import MobileSync
    import QuranKit
    import ReadingService

    public struct AyahBookmarkCollection {
        public let collection: Collection_
        public let bookmarks: [AyahCollectionBookmark]
    }

    public struct AyahCollectionBookmark {
        public let bookmark: CollectionAyahBookmark
        public let ayah: AyahNumber
    }

    public struct AyahBookmarkCollectionService {
        // MARK: Lifecycle

        public init(
            syncService: SyncService,
            readingPreferences: ReadingPreferences = .shared
        ) {
            self.syncService = syncService
            self.readingPreferences = readingPreferences
        }

        // MARK: Public

        public func observeCollections(_ handler: ([AyahBookmarkCollection]) -> Void) async throws {
            let sequence = syncService.collectionsWithBookmarksSequence()
                .map { collections in
                    self.collections(from: collections)
                }
            for try await collections in sequence {
                handler(collections)
            }
        }

        public func collectionsSnapshot() async throws -> [AyahBookmarkCollection] {
            let sequence = syncService.collectionsWithBookmarksSequence()
                .map { collections in
                    self.collections(from: collections)
                }
            var iterator = sequence.makeAsyncIterator()
            return try await iterator.next() ?? []
        }

        public func createCollection(named name: String) async throws {
            try await syncService.createCollection(named: name)
        }

        public func addAyahBookmarkToCollection(collectionLocalId: String, ayah: AyahNumber) async throws {
            _ = try await syncService.addAyahBookmarkToCollection(
                collectionLocalId: collectionLocalId,
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah)
            )
        }

        public func removeCollection(localId: String) async throws {
            try await syncService.removeCollection(localId: localId)
        }

        public func removeBookmarkFromCollection(_ bookmark: AyahCollectionBookmark) async throws {
            try await syncService.removeAyahBookmarkFromCollection(bookmark.bookmark)
        }

        // MARK: Internal

        static func collections(from collections: [CollectionWithAyahBookmarks], quran: Quran) -> [AyahBookmarkCollection] {
            collections.map { collection in
                AyahBookmarkCollection(
                    collection: collection.collection,
                    bookmarks: collection.bookmarks.compactMap { bookmark(for: $0, quran: quran) }
                )
            }
        }

        func collectionsSequence() -> some AsyncSequence {
            syncService.collectionsWithBookmarksSequence()
                .map { collections in
                    self.collections(from: collections)
                }
        }

        // MARK: Private

        private let syncService: SyncService
        private let readingPreferences: ReadingPreferences

        private static func bookmark(for bookmark: CollectionAyahBookmark, quran: Quran) -> AyahCollectionBookmark? {
            guard let ayah = AyahNumber(
                quran: quran,
                sura: Int(bookmark.sura),
                ayah: Int(bookmark.ayah)
            ) else {
                return nil
            }

            return AyahCollectionBookmark(bookmark: bookmark, ayah: ayah)
        }

        private func collections(from collections: [CollectionWithAyahBookmarks]) -> [AyahBookmarkCollection] {
            Self.collections(from: collections, quran: readingPreferences.reading.quran)
        }
    }

#endif
