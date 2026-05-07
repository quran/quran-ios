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
            self.readingPreferences = readingPreferences
        }

        // MARK: Internal

        func collectionsSequence<S: AsyncSequence>(_ sequence: S) -> AsyncThrowingStream<[AyahBookmarkCollection], Error>
            where S.Element == [CollectionWithAyahBookmarks]
        {
            AsyncThrowingStream { continuation in
                let task = Task {
                    do {
                        for try await collections in sequence {
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

        private let readingPreferences: ReadingPreferences

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

    extension SyncService {
        func removeBookmarkFromCollection(_ bookmark: AyahCollectionBookmark) async throws {
            try await removeBookmarkFromCollection(
                collectionLocalId: bookmark.bookmark.collectionLocalId,
                bookmark: AyahBookmark(
                    sura: bookmark.bookmark.sura,
                    ayah: bookmark.bookmark.ayah,
                    lastUpdated: bookmark.bookmark.lastUpdated,
                    localId: bookmark.bookmark.bookmarkLocalId
                )
            )
        }
    }
#endif
