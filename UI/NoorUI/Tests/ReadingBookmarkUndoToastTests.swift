#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import XCTest
@testable import NoorUI

final class ReadingBookmarkUndoToastTests: XCTestCase {
    func test_removed_showsOutlineRibbonInSlotColor() {
        let toast = ReadingBookmarkUndoToast.removed(bookmark(slot: .red)) {}

        XCTAssertEqual(toast.icon?.systemImage, .bookmarkOutline)
        XCTAssertEqual(toast.icon?.color, ReadingBookmarkSlot.red.swiftUIColor)
    }

    func test_saved_showsFilledRibbonInSlotColor() {
        let toast = ReadingBookmarkUndoToast.saved(bookmark(slot: .teal))

        XCTAssertEqual(toast.icon?.systemImage, .bookmark)
        XCTAssertEqual(toast.icon?.color, ReadingBookmarkSlot.teal.swiftUIColor)
    }

    private func bookmark(slot: ReadingBookmarkSlot) -> PlacedReadingBookmark {
        let ayah = Quran.hafsMadani1405.suras[1].verses[254]
        return PlacedReadingBookmark(id: "bookmark", slot: slot, placement: .ayah(ayah), modifiedOn: .distantPast)
    }
}
#endif
