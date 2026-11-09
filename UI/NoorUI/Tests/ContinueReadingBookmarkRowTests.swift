#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import XCTest
@testable import NoorUI

@MainActor
final class ContinueReadingBookmarkRowTests: XCTestCase {
    private let locale = Locale(identifier: "en")
    private let page = Quran.hafsMadani1405.pages[2]
    private let ayah = Quran.hafsMadani1405.suras[1].verses[4]

    func test_unnamedPageBookmark_showsSurasAndKeepsThePageInTheSubtitle() {
        let row = makeRow(placement: .page(page))

        XCTAssertEqual(text(row.title), text("\(suras: page.suras)"))
        XCTAssertEqual(text(row.subtitle), "\(page.localizedName) · \(Date.distantPast.timeAgo())")
    }

    func test_namedPageBookmark_showsNameAndMovesSurasToTheSubtitle() {
        let row = makeRow(placement: .page(page), name: "Khatmah")

        XCTAssertEqual(text(row.title), "Khatmah")
        XCTAssertEqual(
            text(row.subtitle),
            text("\(suras: page.suras) · \(page.localizedName) · \(Date.distantPast.timeAgo())")
        )
    }

    func test_unnamedAyahBookmark_showsAyahAndOnlyTheTimeInTheSubtitle() {
        let row = makeRow(placement: .ayah(ayah))

        XCTAssertEqual(text(row.title), text("\(ayah: ayah)"))
        XCTAssertEqual(text(row.subtitle), Date.distantPast.timeAgo())
    }

    func test_namedAyahBookmark_showsNameAndMovesAyahToTheSubtitle() {
        let row = makeRow(placement: .ayah(ayah), name: "Hifz")

        XCTAssertEqual(text(row.title), "Hifz")
        XCTAssertEqual(text(row.subtitle), text("\(ayah: ayah) · \(Date.distantPast.timeAgo())"))
    }

    func test_defaultRow_showsADisclosureIndicator() {
        let row = makeRow(placement: .ayah(ayah))

        guard case .disclosureIndicator = row.accessory else {
            return XCTFail("Expected a disclosure indicator, got \(row.accessory)")
        }
    }

    func test_pageNumberRow_ayahBookmarkShowsThePageHoldingTheAyah() {
        let row = makeRow(placement: .ayah(ayah), showsPageNumber: true)

        XCTAssertEqual(accessoryText(row), [ayah.page.localizedNumber, ayah.page.localizedName])
        XCTAssertEqual(text(row.subtitle), Date.distantPast.timeAgo())
    }

    func test_pageNumberRow_unnamedPageBookmarkShowsThePageOnlyOnce() {
        let row = makeRow(placement: .page(page), showsPageNumber: true)

        XCTAssertEqual(accessoryText(row), [page.localizedNumber, page.localizedName])
        XCTAssertEqual(text(row.subtitle), Date.distantPast.timeAgo())
    }

    func test_pageNumberRow_namedPageBookmarkKeepsSurasInTheSubtitle() {
        let row = makeRow(placement: .page(page), name: "Khatmah", showsPageNumber: true)

        XCTAssertEqual(text(row.title), "Khatmah")
        XCTAssertEqual(text(row.subtitle), text("\(suras: page.suras) · \(Date.distantPast.timeAgo())"))
    }

    private func makeRow(
        placement: PlacedReadingBookmark.Placement,
        name: String? = nil,
        showsPageNumber: Bool = false
    ) -> ContinueReadingBookmarkRow {
        ContinueReadingBookmarkRow(
            bookmark: PlacedReadingBookmark(id: "row", slot: .teal, placement: placement, modifiedOn: .distantPast, name: name),
            showsPageNumber: showsPageNumber,
            action: {}
        )
    }

    private func accessoryText(_ row: ContinueReadingBookmarkRow) -> [String?] {
        guard case .text(let text, let accessibilityLabel) = row.accessory else {
            XCTFail("Expected a page number, got \(row.accessory)")
            return []
        }
        return [text, accessibilityLabel]
    }

    private func text(_ text: MultipartText) -> String {
        text.rawValue(locale: locale)
    }
}
#endif
