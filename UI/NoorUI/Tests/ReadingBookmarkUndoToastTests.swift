#if QURAN_SYNC
import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import XCTest
@testable import NoorUI

final class ReadingBookmarkUndoToastTests: XCTestCase {
    func test_removed_showsOutlineRibbonInSlotColor() {
        let toast = ReadingBookmarkUndoToast.removed(bookmark(slot: .red)) {}

        XCTAssertEqual(toast.icon?.systemImage, .bookmarkOutline)
        XCTAssertEqual(toast.icon?.color, ReadingBookmarkSlot.red.swiftUIColor)
    }

    func test_saved_showsFilledRibbonInSlotColor() {
        let toast = ReadingBookmarkUndoToast.saved(bookmark(slot: .teal), showsExplanation: false)

        XCTAssertEqual(toast.icon?.systemImage, .bookmark)
        XCTAssertEqual(toast.icon?.color, ReadingBookmarkSlot.teal.swiftUIColor)
    }

    func test_moved_namesOnlyTheDestination() {
        let toast = ReadingBookmarkUndoToast.moved(to: bookmark(slot: .orange), showsExplanation: false) {}

        XCTAssertEqual(toast.message.accessibilityText, lFormat("ayah.menu.reading-bookmark.moved-to", ayah.localizedName))
    }

    // MARK: Private

    private let ayah = Quran.hafsMadani1405.suras[1].verses[254]

    private func bookmark(slot: ReadingBookmarkSlot) -> PlacedReadingBookmark {
        PlacedReadingBookmark(id: "bookmark", slot: slot, placement: .ayah(ayah), modifiedOn: .distantPast)
    }
}
#endif
