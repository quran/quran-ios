#if QURAN_SYNC
    import MobileSync
    import QuranKit
    import XCTest
    @testable import BookmarksFeature

    final class AyahBookmarkCollectionPickerViewModelTests: XCTestCase {
        func test_bookmarksToAdd_skipsExistingBookmarks() {
            let existingAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
            let newAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2)!
            let collection = AyahBookmarkCollection(
                collection: Collection_(name: "Favorites", lastUpdated: .distantPast, localId: "favorites"),
                bookmarks: [
                    AyahCollectionBookmark(
                        bookmark: CollectionAyahBookmark(
                            collectionLocalId: "favorites",
                            collectionRemoteId: nil,
                            bookmarkLocalId: "bookmark-1",
                            bookmarkRemoteId: nil,
                            sura: 1,
                            ayah: 1,
                            lastUpdated: .distantPast,
                            localId: "collection-bookmark-1"
                        ),
                        ayah: existingAyah
                    ),
                ]
            )

            XCTAssertEqual(
                AyahBookmarkCollectionPickerViewModel.bookmarksToAdd(to: collection, verses: [existingAyah, newAyah]),
                [newAyah]
            )
        }

        func test_bookmarksToRemove_returnsExistingBookmarks() {
            let existingAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
            let newAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2)!
            let collection = AyahBookmarkCollection(
                collection: Collection_(name: "Favorites", lastUpdated: .distantPast, localId: "favorites"),
                bookmarks: [
                    AyahCollectionBookmark(
                        bookmark: CollectionAyahBookmark(
                            collectionLocalId: "favorites",
                            collectionRemoteId: nil,
                            bookmarkLocalId: "bookmark-1",
                            bookmarkRemoteId: nil,
                            sura: 1,
                            ayah: 1,
                            lastUpdated: .distantPast,
                            localId: "collection-bookmark-1"
                        ),
                        ayah: existingAyah
                    ),
                ]
            )

            let bookmarks = AyahBookmarkCollectionPickerViewModel.bookmarksToRemove(
                from: collection,
                verses: [existingAyah, newAyah]
            )

            XCTAssertEqual(bookmarks.map(\.bookmark.localId), ["collection-bookmark-1"])
        }

        func test_containsAnyBookmark_detectsExistingBookmark() {
            let existingAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
            let newAyah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2)!
            let collection = AyahBookmarkCollection(
                collection: Collection_(name: "Favorites", lastUpdated: .distantPast, localId: "favorites"),
                bookmarks: [
                    AyahCollectionBookmark(
                        bookmark: CollectionAyahBookmark(
                            collectionLocalId: "favorites",
                            collectionRemoteId: nil,
                            bookmarkLocalId: "bookmark-1",
                            bookmarkRemoteId: nil,
                            sura: 1,
                            ayah: 1,
                            lastUpdated: .distantPast,
                            localId: "collection-bookmark-1"
                        ),
                        ayah: existingAyah
                    ),
                ]
            )

            XCTAssertTrue(AyahBookmarkCollectionPickerViewModel.containsAnyBookmark(in: collection, verses: [existingAyah, newAyah]))
            XCTAssertFalse(AyahBookmarkCollectionPickerViewModel.containsAnyBookmark(in: collection, verses: [newAyah]))
        }
    }
#endif
