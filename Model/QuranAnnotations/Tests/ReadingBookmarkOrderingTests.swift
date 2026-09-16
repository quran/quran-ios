#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest

final class ReadingBookmarkOrderingTests: XCTestCase {
    func test_readingBookmarks_ordersNewestFirstRegardlessOfPinColor() {
        let oldest = bookmark(id: "oldest", slot: .coral, timestamp: 100)
        let newest = bookmark(id: "newest", slot: .indigo, timestamp: 300)
        let middle = bookmark(id: "middle", slot: .teal, timestamp: 200)

        let bookmarks = PlacedReadingBookmark.sortedByDate([oldest, newest, middle])

        XCTAssertEqual(bookmarks, [newest, middle, oldest])
    }

    func test_readingBookmarks_usesStableOrderForMatchingDates() {
        let first = bookmark(id: "a", slot: .indigo, timestamp: 100)
        let second = bookmark(id: "b", slot: .teal, timestamp: 100)

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
