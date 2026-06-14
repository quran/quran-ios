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

    public struct AyahBookmarkCollectionsSequence: AsyncSequence {
        public typealias Element = [AyahBookmarkCollection]

        public struct AsyncIterator: AsyncIteratorProtocol {
            init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
                var iterator = sequence.makeAsyncIterator()
                nextValue = {
                    try await iterator.next()
                }
            }

            public mutating func next() async throws -> Element? {
                try await nextValue()
            }

            private let nextValue: () async throws -> Element?
        }

        init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
            makeIterator = {
                AsyncIterator(sequence)
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            makeIterator()
        }

        private let makeIterator: () -> AsyncIterator
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

        public func setAyahBookmarks(
            _ ayahs: [AyahNumber],
            toCollectionNamed targetCollectionName: String,
            removingFromCollectionNames collectionNames: [String]
        ) async throws {
            let collections = try await collectionsFirstValue()
            let targetCollection = try await collection(named: targetCollectionName, in: collections)

            let targetAyahs = Set(
                targetCollection.bookmarks
                    .filter { ayahs.contains($0.ayah) }
                    .map(\.ayah)
            )

            for collection in collections where collectionNames.contains(collection.collection.name) {
                for bookmark in collection.bookmarks where ayahs.contains(bookmark.ayah) {
                    if collection.collection.localId != targetCollection.collection.localId {
                        try await removeBookmarkFromCollection(bookmark)
                    }
                }
            }

            for ayah in ayahs where !targetAyahs.contains(ayah) {
                try await addAyahBookmarkToCollection(
                    collectionLocalId: targetCollection.collection.localId,
                    ayah: ayah
                )
            }
        }

        public func removeAyahBookmarks(
            _ ayahs: [AyahNumber],
            fromCollectionNames collectionNames: [String]
        ) async throws {
            let collections = try await collectionsFirstValue()
            for collection in collections where collectionNames.contains(collection.collection.name) {
                for bookmark in collection.bookmarks where ayahs.contains(bookmark.ayah) {
                    try await removeBookmarkFromCollection(bookmark)
                }
            }
        }

        public func collectionsSequence() -> AyahBookmarkCollectionsSequence {
            let readingPreferences = readingPreferences
            let sequence = syncService.collectionsWithBookmarksSequence()
                .map { collections in
                    Self.collections(
                        from: collections,
                        quran: readingPreferences.reading.quran
                    )
                }
            return AyahBookmarkCollectionsSequence(sequence)
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

        private func collectionsFirstValue() async throws -> [AyahBookmarkCollection] {
            var iterator = collectionsSequence().makeAsyncIterator()
            return try await iterator.next() ?? []
        }

        private func collection(named name: String, in collections: [AyahBookmarkCollection]) async throws -> AyahBookmarkCollection {
            if let collection = collections.first(where: { $0.collection.name == name }) {
                return collection
            }

            try await createCollection(named: name)

            let updatedCollections = try await collectionsFirstValue()
            guard let collection = updatedCollections.first(where: { $0.collection.name == name }) else {
                throw AyahBookmarkCollectionServiceError.collectionUnavailable
            }
            return collection
        }
    }

    private enum AyahBookmarkCollectionServiceError: Error {
        case collectionUnavailable
    }

#endif
