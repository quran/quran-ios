#if QURAN_SYNC
    import Foundation
    import MobileSync
    import QuranAnnotations
    import QuranKit
    import XCTest
    @testable import BookmarksFeature

    @MainActor
    final class OldPageBookmarksCollectionSyncTests: XCTestCase {
        func test_sync_createsSystemCollectionAndCopiesMissingAyahBookmarks() async throws {
            let legacyBookmarks = [
                PageBookmark(page: Quran.hafsMadani1405.pages[0], creationDate: .distantPast),
                PageBookmark(page: Quran.hafsMadani1405.pages[1], creationDate: .distantPast),
            ]
            var collections: [CollectionWithAyahBookmarks] = []
            var createdCollectionNames: [String] = []
            var addedBookmarks: [CollectionAyahBookmark] = []

            let sut = OldPageBookmarksCollectionSync(
                collectionsSnapshot: {
                    collections
                },
                createCollection: { name in
                    createdCollectionNames.append(name)
                    let collection = Collection_(
                        name: name,
                        lastUpdated: .distantPast,
                        localId: "collection-\(createdCollectionNames.count)"
                    )
                    collections = [CollectionWithAyahBookmarks(collection: collection, bookmarks: [])]
                },
                addAyahBookmarkToCollection: { collectionLocalId, sura, ayah in
                    let bookmark = CollectionAyahBookmark(
                        collectionLocalId: collectionLocalId,
                        collectionRemoteId: nil,
                        bookmarkLocalId: "bookmark-\(addedBookmarks.count + 1)",
                        bookmarkRemoteId: nil,
                        sura: sura,
                        ayah: ayah,
                        lastUpdated: .distantPast,
                        localId: "collection-bookmark-\(addedBookmarks.count + 1)"
                    )
                    addedBookmarks.append(bookmark)
                    collections[0] = CollectionWithAyahBookmarks(
                        collection: collections[0].collection,
                        bookmarks: collections[0].bookmarks + [bookmark]
                    )
                    return bookmark
                },
                legacyPageBookmarksSnapshot: {
                    legacyBookmarks
                }
            )

            try await sut.sync()

            XCTAssertEqual(createdCollectionNames, [OldPageBookmarksCollectionSync.collectionName])
            XCTAssertEqual(addedBookmarks.count, legacyBookmarks.count)
            XCTAssertEqual(collections.first?.bookmarks.count, legacyBookmarks.count)
        }

        func test_sync_skipsAyahBookmarksAlreadyInCollection() async throws {
            let existingAyah = Quran.hafsMadani1405.pages[0].firstVerse
            let missingAyah = Quran.hafsMadani1405.pages[1].firstVerse
            let legacyBookmarks = [
                PageBookmark(page: Quran.hafsMadani1405.pages[0], creationDate: .distantPast),
                PageBookmark(page: Quran.hafsMadani1405.pages[1], creationDate: .distantPast),
            ]
            var collections = [
                CollectionWithAyahBookmarks(
                    collection: Collection_(
                        name: OldPageBookmarksCollectionSync.collectionName,
                        lastUpdated: .distantPast,
                        localId: "collection-1"
                    ),
                    bookmarks: [
                        CollectionAyahBookmark(
                            collectionLocalId: "collection-1",
                            collectionRemoteId: nil,
                            bookmarkLocalId: "bookmark-1",
                            bookmarkRemoteId: nil,
                            sura: Int32(existingAyah.sura.suraNumber),
                            ayah: Int32(existingAyah.ayah),
                            lastUpdated: .distantPast,
                            localId: "collection-bookmark-1"
                        ),
                    ]
                ),
            ]
            var createdCollectionNames: [String] = []
            var addedBookmarks: [CollectionAyahBookmark] = []

            let sut = OldPageBookmarksCollectionSync(
                collectionsSnapshot: {
                    collections
                },
                createCollection: { name in
                    createdCollectionNames.append(name)
                },
                addAyahBookmarkToCollection: { collectionLocalId, sura, ayah in
                    let bookmark = CollectionAyahBookmark(
                        collectionLocalId: collectionLocalId,
                        collectionRemoteId: nil,
                        bookmarkLocalId: "bookmark-\(addedBookmarks.count + 2)",
                        bookmarkRemoteId: nil,
                        sura: sura,
                        ayah: ayah,
                        lastUpdated: .distantPast,
                        localId: "collection-bookmark-\(addedBookmarks.count + 2)"
                    )
                    addedBookmarks.append(bookmark)
                    collections[0] = CollectionWithAyahBookmarks(
                        collection: collections[0].collection,
                        bookmarks: collections[0].bookmarks + [bookmark]
                    )
                    return bookmark
                },
                legacyPageBookmarksSnapshot: {
                    legacyBookmarks
                }
            )

            try await sut.sync()

            XCTAssertEqual(createdCollectionNames, [])
            XCTAssertEqual(addedBookmarks.count, 1)
            XCTAssertEqual(addedBookmarks.first?.sura, Int32(missingAyah.sura.suraNumber))
            XCTAssertEqual(addedBookmarks.first?.ayah, Int32(missingAyah.ayah))
            XCTAssertEqual(collections.first?.bookmarks.count, 2)
        }
    }
#endif
