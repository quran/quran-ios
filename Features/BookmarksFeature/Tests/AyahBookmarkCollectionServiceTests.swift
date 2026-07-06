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

        func test_ayahsToAdd_skipsExistingBookmarks() {
            let existingAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
            let missingAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2)!
            let collection = Self.ayahBookmarkCollection(
                name: "Favorites",
                bookmarks: [
                    Self.ayahCollectionBookmark(collectionLocalId: "Favorites", ayah: existingAyah),
                ]
            )

            let ayahsToAdd = AyahBookmarkCollectionService.ayahsToAdd(
                [existingAyah, missingAyah],
                to: collection
            )

            XCTAssertEqual(ayahsToAdd, [missingAyah])
        }

        func test_ayahsToAdd_deduplicatesInputAyahs() {
            let firstAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
            let secondAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2)!
            let collection = Self.ayahBookmarkCollection(name: "Favorites")

            let ayahsToAdd = AyahBookmarkCollectionService.ayahsToAdd(
                [firstAyah, firstAyah, secondAyah, firstAyah],
                to: collection
            )

            XCTAssertEqual(ayahsToAdd, [firstAyah, secondAyah])
        }

        func test_highlightCollectionCreationPlanner_reservesMultipleMissingCollections() async {
            let sut = HighlightCollectionCreationPlanner()

            let names = await sut.reserveMissingCollectionNames(from: [
                Self.ayahBookmarkCollection(name: "yellow"),
                Self.ayahBookmarkCollection(name: "Favorites"),
            ])

            XCTAssertEqual(names, ["green", "blue", "red", "purple"])
        }

        func test_highlightCollectionCreationPlanner_doesNotDuplicateReservedCollectionsForStaleEmissions() async {
            let sut = HighlightCollectionCreationPlanner()

            let initialNames = await sut.reserveMissingCollectionNames(from: [
                Self.ayahBookmarkCollection(name: "Favorites"),
            ])
            let staleNames = await sut.reserveMissingCollectionNames(from: [
                Self.ayahBookmarkCollection(name: "yellow"),
            ])

            XCTAssertEqual(initialNames, ["yellow", "green", "blue", "red", "purple"])
            XCTAssertEqual(staleNames, [])
        }

        func test_highlightCollectionCreationPlanner_releasesOnlyFailedReservations() async {
            let sut = HighlightCollectionCreationPlanner()

            let initialNames = await sut.reserveMissingCollectionNames(from: [
                Self.ayahBookmarkCollection(name: "Favorites"),
            ])
            await sut.releaseCollectionNames([initialNames[1]])
            let retryNames = await sut.reserveMissingCollectionNames(from: [
                Self.ayahBookmarkCollection(name: "yellow"),
            ])

            XCTAssertEqual(retryNames, ["green"])
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

        private static func ayahBookmarkCollection(
            name: String,
            bookmarks: [AyahCollectionBookmark] = []
        ) -> AyahBookmarkCollection {
            AyahBookmarkCollection(
                collection: Collection_(
                    name: name,
                    lastUpdated: .distantPast,
                    localId: name
                ),
                bookmarks: bookmarks
            )
        }

        private static func ayahCollectionBookmark(
            collectionLocalId: String,
            ayah: AyahNumber
        ) -> AyahCollectionBookmark {
            AyahCollectionBookmark(
                bookmark: bookmark(
                    collectionLocalId: collectionLocalId,
                    sura: Int32(ayah.sura.suraNumber),
                    ayah: Int32(ayah.ayah)
                ),
                ayah: ayah
            )
        }
    }
#endif
