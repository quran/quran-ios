#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import XCTest
@testable import NoorUI

@MainActor
final class ContinueReadingBookmarkRowTests: XCTestCase {
    private let locale = Locale(identifier: "en")
    private let quran = Quran.hafsMadani1405
    private var timeAgo: String { Date.distantPast.timeAgo() }

    func test_unnamedPageBookmark_showsFirstSuraAndPageWithOnlyTheTimeInTheSubtitle() {
        let page = quran.pages[22]
        let row = makeRow(placement: .page(page))

        XCTAssertEqual(text(row.title), "Al-Baqarah, Page 23")
        XCTAssertEqual(text(row.subtitle), timeAgo)
    }

    func test_pageBookmark_onAPageWithSeveralSuras_namesOnlyTheFirstSura() {
        let page = quran.pages[603]
        XCTAssertGreaterThan(page.suras.count, 1)

        let row = makeRow(placement: .page(page))

        XCTAssertEqual(text(row.title), "Al-Ikhlāṣ, Page 604")
    }

    func test_namedPageBookmark_movesSuraAndPageToTheSubtitle() {
        let row = makeRow(placement: .page(quran.pages[22]), name: "Khatmah")

        XCTAssertEqual(text(row.title), "Khatmah")
        XCTAssertEqual(text(row.subtitle), "Al-Baqarah, Page 23 · \(timeAgo)")
    }

    func test_unnamedAyahBookmark_showsAyahAndPutsThePageHoldingItInTheSubtitle() {
        let ayah = quran.suras[66].verses[17]
        let row = makeRow(placement: .ayah(ayah))

        XCTAssertEqual(text(row.title), text("\(ayah: ayah)"))
        XCTAssertEqual(text(row.subtitle), "Page 563 · \(timeAgo)")
    }

    func test_ayahBookmark_usesThePageThatOpensWithTheAyah() {
        XCTAssertEqual(text(makeRow(placement: .ayah(quran.suras[66].verses[12])).subtitle), "Page 563 · \(timeAgo)")
        XCTAssertEqual(text(makeRow(placement: .ayah(quran.suras[66].verses[11])).subtitle), "Page 562 · \(timeAgo)")
    }

    func test_namedAyahBookmark_movesAyahToTheSubtitleBeforeThePage() {
        let ayah = quran.suras[66].verses[17]
        let row = makeRow(placement: .ayah(ayah), name: "Hifz")

        XCTAssertEqual(text(row.title), "Hifz")
        XCTAssertEqual(text(row.subtitle), text("\(ayah: ayah) · Page 563 · \(timeAgo)"))
    }

    private func makeRow(placement: PlacedReadingBookmark.Placement, name: String? = nil) -> ContinueReadingBookmarkRow {
        ContinueReadingBookmarkRow(
            bookmark: PlacedReadingBookmark(id: "row", slot: .teal, placement: placement, modifiedOn: .distantPast, name: name),
            action: {}
        )
    }

    private func text(_ text: MultipartText) -> String {
        text.rawValue(locale: locale)
    }
}
#endif
