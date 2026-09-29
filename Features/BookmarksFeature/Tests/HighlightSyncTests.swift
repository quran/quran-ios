#if QURAN_SYNC
import QuranAnnotations
import XCTest

final class HighlightSyncTests: XCTestCase {
    func test_highlightColorsIncludeEveryMobileSyncColor() {
        XCTAssertEqual(
            HighlightColor.sortedColors,
            [.yellow, .green, .blue, .pink, .purple]
        )
    }
}
#endif
