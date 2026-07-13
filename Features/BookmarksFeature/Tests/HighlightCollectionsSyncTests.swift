#if QURAN_SYNC
import QuranAnnotations
import XCTest

final class HighlightCollectionsSyncTests: XCTestCase {
    func test_collectionName_matchesFixedRawValue() {
        XCTAssertEqual(HighlightColor.red.collectionName, "red")
        XCTAssertEqual(HighlightColor.green.collectionName, "green")
        XCTAssertEqual(HighlightColor.blue.collectionName, "blue")
        XCTAssertEqual(HighlightColor.yellow.collectionName, "yellow")
        XCTAssertEqual(HighlightColor.purple.collectionName, "purple")
    }
}
#endif
