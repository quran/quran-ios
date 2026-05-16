#if QURAN_SYNC
    import MobileSync
    import QuranKit
    import XCTest
    @testable import BookmarksFeature

    final class AyahBookmarkCollectionServiceTests: XCTestCase {
        // MARK: Internal

        func test_collections_mapsAyahNumbers() {
            let collections = AyahBookmarkCollectionService.collections(from: [
                Self.collection(
                    name: "Favorites",
                    bookmarks: [
                        Self.bookmark(collectionLocalId: "favorites", sura: 1, ayah: 1),
                    ]
                ),
            ], quran: .hafsMadani1405)

            XCTAssertEqual(collections.count, 1)
            XCTAssertEqual(collections[0].collection.name, "Favorites")
            XCTAssertEqual(collections[0].bookmarks.count, 1)
            XCTAssertEqual(collections[0].bookmarks[0].ayah, AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1))
        }

        func test_collections_skipsInvalidAyahs() {
            let collections = AyahBookmarkCollectionService.collections(from: [
                Self.collection(
                    name: "Favorites",
                    bookmarks: [
                        Self.bookmark(collectionLocalId: "favorites", sura: 999, ayah: 1),
                    ]
                ),
            ], quran: .hafsMadani1405)

            XCTAssertEqual(collections.count, 1)
            XCTAssertTrue(collections[0].bookmarks.isEmpty)
        }

        func test_bookmarks_mapsAyahNumbers() {
            let bookmarks = AyahBookmarkCollectionService.bookmarks(from: [
                Self.ayahBookmark(sura: 1, ayah: 1),
            ], quran: .hafsMadani1405)

            XCTAssertEqual(bookmarks.count, 1)
            XCTAssertEqual(bookmarks[0].ayah, AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1))
        }

        func test_favourites_skipsBookmarksAlreadyLinkedToCollections() {
            let quran = Quran.hafsMadani1405
            let linkedBookmark = Self.ayahBookmark(localId: "bookmark-1", sura: 1, ayah: 1)
            let unlinkedBookmark = Self.ayahBookmark(localId: "bookmark-2", sura: 1, ayah: 2)
            let directBookmarks = AyahBookmarkCollectionService.bookmarks(from: [linkedBookmark, unlinkedBookmark], quran: quran)
            let collections = AyahBookmarkCollectionService.collections(from: [
                Self.collection(
                    name: "Collection",
                    bookmarks: [Self.bookmark(collectionLocalId: "collection", bookmarkLocalId: "bookmark-1", sura: 1, ayah: 1)]
                ),
            ], quran: quran)

            let favourites = FavouritesBookmarkCollection.make(
                name: "Favourites",
                bookmarks: directBookmarks,
                collections: collections
            )

            XCTAssertEqual(favourites.bookmarks.map(\.ayah), [AyahNumber(quran: quran, sura: 1, ayah: 2)!])
            XCTAssertTrue(favourites.isLocalOnly)
        }

        // MARK: Private

        private static func collection(
            localId: String? = nil,
            name: String,
            bookmarks: [CollectionAyahBookmark]
        ) -> CollectionWithAyahBookmarks {
            CollectionWithAyahBookmarks(
                collection: Collection_(
                    name: name,
                    lastUpdated: .distantPast,
                    localId: localId ?? name
                ),
                bookmarks: bookmarks
            )
        }

        private static func ayahBookmark(
            localId: String? = nil,
            sura: Int32,
            ayah: Int32
        ) -> AyahBookmark {
            AyahBookmark(
                sura: sura,
                ayah: ayah,
                lastUpdated: .distantPast,
                localId: localId ?? "bookmark-\(sura)-\(ayah)"
            )
        }

        private static func bookmark(
            collectionLocalId: String,
            bookmarkLocalId: String? = nil,
            sura: Int32,
            ayah: Int32
        ) -> CollectionAyahBookmark {
            CollectionAyahBookmark(
                collectionLocalId: collectionLocalId,
                collectionRemoteId: nil,
                bookmarkLocalId: bookmarkLocalId ?? "\(collectionLocalId)-\(sura)-\(ayah)",
                bookmarkRemoteId: nil,
                sura: sura,
                ayah: ayah,
                lastUpdated: .distantPast,
                localId: "\(collectionLocalId)-collection-\(sura)-\(ayah)"
            )
        }
    }
#endif
