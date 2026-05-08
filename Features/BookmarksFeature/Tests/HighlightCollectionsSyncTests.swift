#if QURAN_SYNC
    import QuranAnnotations
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

        func test_collectionName_matchesFixedRawValue() {
            XCTAssertEqual(HighlightColor.red.collectionName, "red")
            XCTAssertEqual(HighlightColor.green.collectionName, "green")
            XCTAssertEqual(HighlightColor.blue.collectionName, "blue")
            XCTAssertEqual(HighlightColor.yellow.collectionName, "yellow")
            XCTAssertEqual(HighlightColor.purple.collectionName, "purple")
        }
    }
#endif
