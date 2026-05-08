#if QURAN_SYNC
    import FeaturesSupport
    import MobileSync
    import QuranAnnotations
    import QuranKit
    import XCTest

    final class HighlightCollectionsSyncTests: XCTestCase {
        func test_highlightColor_matchesFixedCollectionNames() {
            XCTAssertEqual(HighlightColor(collectionName: "red"), .red)
            XCTAssertEqual(HighlightColor(collectionName: "green"), .green)
            XCTAssertEqual(HighlightColor(collectionName: "blue"), .blue)
            XCTAssertEqual(HighlightColor(collectionName: "yellow"), .yellow)
            XCTAssertEqual(HighlightColor(collectionName: "purple"), .purple)
            XCTAssertNil(HighlightColor(collectionName: "Red"))
            XCTAssertNil(HighlightColor(collectionName: "bookmarks"))
        }

        func test_highlightedAyahs_mapsOnlyHighlightCollections() {
            let quran = Quran.hafsMadani1405
            let collections = [
                Self.collection(name: "red", bookmarks: [Self.bookmark(collectionLocalId: "red", sura: 1, ayah: 1)]),
                Self.collection(name: "bookmarks", bookmarks: [Self.bookmark(collectionLocalId: "bookmarks", sura: 1, ayah: 2)]),
            ]

            let highlights = collections.highlightedAyahs(quran: quran)

            XCTAssertEqual(highlights[AyahNumber(quran: quran, sura: 1, ayah: 1)!], .red)
            XCTAssertNil(highlights[AyahNumber(quran: quran, sura: 1, ayah: 2)!])
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
