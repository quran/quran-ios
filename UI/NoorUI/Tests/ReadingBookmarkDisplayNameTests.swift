#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import XCTest
@testable import NoorUI

final class ReadingBookmarkDisplayNameTests: XCTestCase {
    func test_displayName_usesCustomNameAndFallsBackToSlot() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        for name in ["Hifz", nil] as [String?] {
            let bookmark = PlacedReadingBookmark(
                id: "coral", slot: .coral, placement: .ayah(ayah), modifiedOn: .distantPast, name: name
            )

            XCTAssertEqual(bookmark.displayName, name ?? ReadingBookmarkSlot.coral.displayName)
            XCTAssertEqual(ReadingBookmark(bookmark).displayName, bookmark.displayName)
        }
    }
}
#endif
