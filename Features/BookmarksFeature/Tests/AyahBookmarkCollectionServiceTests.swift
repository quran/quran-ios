#if QURAN_SYNC
    import MobileSync
    import QuranKit
    import XCTest
    @testable import BookmarksFeature

    final class AyahBookmarkCollectionServiceTests: XCTestCase {
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
