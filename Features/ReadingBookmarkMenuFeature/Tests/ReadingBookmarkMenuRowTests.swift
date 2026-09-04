#if QURAN_SYNC
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import XCTest
@testable import ReadingBookmarkMenuFeature

@MainActor
final class ReadingBookmarkMenuRowTests: XCTestCase {
    func test_unplacedBookmark_offersSetHere() {
        let row = makeRow(placement: .unplaced, target: .ayah(ayah(2)))

        XCTAssertEqual(row.action, .setHere)
        XCTAssertEqual(row.subtitle.accessibilityText, "Not placed yet")
    }

    func test_bookmarkAtCurrentAyah_offersRemove() {
        let row = makeRow(placement: .ayah(ayah(2)), target: .ayah(ayah(2)))

        XCTAssertEqual(row.action, .remove)
        XCTAssertEqual(row.subtitle.accessibilityText, "Saved here")
    }

    func test_bookmarkAtAnotherAyah_offersMoveHere() {
        let row = makeRow(placement: .ayah(ayah(3)), target: .ayah(ayah(2)))

        XCTAssertEqual(row.action, .moveHere)
        XCTAssertEqual(row.subtitle.accessibilityText, "at Al-Fātihah, Ayah 3")
    }

    func test_bookmarkAtCurrentPage_offersRemove() {
        let page = Quran.hafsMadani1405.pages[40]
        let row = makeRow(placement: .page(page), target: .page(page))

        XCTAssertEqual(row.action, .remove)
        XCTAssertEqual(row.subtitle.accessibilityText, "Saved here")
    }

    func test_pageBookmarkAtAyahTarget_offersMoveHere() {
        let page = Quran.hafsMadani1405.pages[0]
        let row = makeRow(placement: .page(page), target: .ayah(ayah(2)))

        XCTAssertEqual(row.action, .moveHere)
        XCTAssertEqual(row.subtitle.accessibilityText, "at \(page.localizedName)")
    }

    private func makeRow(
        placement: ReadingBookmark.Placement,
        target: PlacedReadingBookmark.Placement
    ) -> ReadingBookmarkMenuRow {
        ReadingBookmarkMenuRow(
            item: .init(slot: .coral, name: nil, placement: placement),
            target: target,
            name: .constant(""),
            isEnabled: true,
            editMode: .inactive,
            save: { true },
            select: {}
        )
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}
#endif
