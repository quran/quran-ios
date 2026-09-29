#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest

final class ReadingBookmarkOrderingTests: XCTestCase {
    func test_readingBookmarks_ordersNewestFirstRegardlessOfPinColor() {
        let oldest = bookmark(id: "oldest", slot: .teal, timestamp: 100)
        let newest = bookmark(id: "newest", slot: .red, timestamp: 300)
        let middle = bookmark(id: "middle", slot: .orange, timestamp: 200)

        let bookmarks = PlacedReadingBookmark.sortedByDate([oldest, newest, middle])

        XCTAssertEqual(bookmarks, [newest, middle, oldest])
    }

    func test_readingBookmarks_usesStableOrderForMatchingDates() {
        let first = bookmark(id: "a", slot: .red, timestamp: 100)
        let second = bookmark(id: "b", slot: .orange, timestamp: 100)

        let bookmarks = PlacedReadingBookmark.sortedByDate([second, first])

        XCTAssertEqual(bookmarks, [first, second])
    }

    private func bookmark(id: String, slot: ReadingBookmarkSlot, timestamp: TimeInterval) -> PlacedReadingBookmark {
        PlacedReadingBookmark(
            id: id,
            slot: slot,
            placement: .page(Quran.hafsMadani1405.pages[0]),
            modifiedOn: Date(timeIntervalSince1970: timestamp)
        )
    }
}
#endif
