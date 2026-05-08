#if QURAN_SYNC
    import MobileSync
    import XCTest
    @testable import BookmarksFeature

    final class AyahBookmarkCollectionsViewModelTests: XCTestCase {
        func test_sorted_groupsHighlightCollectionsBeforeUserCollections() {
            let collections = AyahBookmarkCollectionsViewModel.sorted([
                collection(name: "Z Collection"),
                collection(name: "blue"),
                collection(name: "A Collection"),
                collection(name: "red"),
            ])

            XCTAssertEqual(collections.map(\.collection.name), [
                "red",
                "blue",
                "A Collection",
                "Z Collection",
            ])
        }

        private func collection(name: String) -> AyahBookmarkCollection {
            AyahBookmarkCollection(
                collection: Collection_(
                    name: name,
                    lastUpdated: .distantPast,
                    localId: name
                ),
                bookmarks: []
            )
        }
    }
#endif
