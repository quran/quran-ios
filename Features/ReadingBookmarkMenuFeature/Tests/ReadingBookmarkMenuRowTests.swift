#if QURAN_SYNC
import Localization
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
        XCTAssertEqual(row.actionStyle, .plain)
        XCTAssertEqual(row.subtitle.accessibilityText, l("bookmarks.reading.not-placed"))
    }

    func test_firstRun_suggestsTealWithProminentSetHere() {
        let row = makeRow(slot: .teal, placement: .unplaced, target: .ayah(ayah(2)), isFirstRun: true)

        XCTAssertEqual(row.action, .setHere)
        XCTAssertEqual(row.actionStyle, .prominent)
        XCTAssertEqual(row.subtitle.accessibilityText, l("bookmarks.reading.first-run.suggested"))
    }

    func test_firstRun_otherSlotsStayNotPlacedWithPlainSetHere() {
        for slot in [ReadingBookmarkSlot.orange, .red] {
            let row = makeRow(slot: slot, placement: .unplaced, target: .ayah(ayah(2)), isFirstRun: true)

            XCTAssertEqual(row.action, .setHere, "\(slot)")
            XCTAssertEqual(row.actionStyle, .plain, "\(slot)")
            XCTAssertEqual(row.subtitle.accessibilityText, l("bookmarks.reading.not-placed"), "\(slot)")
        }
    }

    func test_bookmarkAtCurrentAyah_offersRemove() {
        let row = makeRow(placement: .ayah(ayah(2)), target: .ayah(ayah(2)))

        XCTAssertEqual(row.action, .remove)
        XCTAssertEqual(row.subtitle.accessibilityText, l("bookmarks.reading.saved-here"))
    }

    func test_bookmarkAtAnotherAyah_offersMoveHere() {
        let row = makeRow(placement: .ayah(ayah(3)), target: .ayah(ayah(2)))

        XCTAssertEqual(row.action, .moveHere)
        XCTAssertEqual(row.actionStyle, .plain)
        XCTAssertEqual(
            row.subtitle.accessibilityText,
            lFormat("bookmarks.reading.location", "Al-Fātihah, Ayah 3")
        )
    }

    func test_bookmarkAtCurrentPage_offersRemove() {
        let page = Quran.hafsMadani1405.pages[40]
        let row = makeRow(placement: .page(page), target: .page(page))

        XCTAssertEqual(row.action, .remove)
        XCTAssertEqual(row.subtitle.accessibilityText, l("bookmarks.reading.saved-here"))
    }

    func test_pageBookmarkAtAyahTarget_offersMoveHere() {
        let page = Quran.hafsMadani1405.pages[199]
        let row = makeRow(placement: .page(page), target: .ayah(ayah(2)))

        XCTAssertEqual(row.action, .moveHere)
        XCTAssertEqual(
            row.subtitle.accessibilityText,
            lFormat("bookmarks.reading.location", "At-Tawbah, Page 200")
        )
    }

    private func makeRow(
        slot: ReadingBookmarkSlot = .teal,
        placement: ReadingBookmark.Placement,
        target: PlacedReadingBookmark.Placement,
        isFirstRun: Bool = false
    ) -> ReadingBookmarkMenuRow {
        ReadingBookmarkMenuRow(
            item: .init(slot: slot, name: nil, placement: placement),
            target: target,
            isFirstRun: isFirstRun,
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
