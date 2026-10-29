#if QURAN_SYNC
import QuranKit
import QuranText
import XCTest
@testable import QuranAnnotations

final class VerseOverlaysIndicatorTests: XCTestCase {
    func test_restricted_keepsCollectionsAndBothBookmarkPlacementsOnThePage() {
        let page = Quran.hafsMadani1405.pages[0]
        let otherPage = Quran.hafsMadani1405.pages[1]
        var overlays = VerseOverlays()
        overlays.collectionVerses = [page.firstVerse, otherPage.firstVerse]
        let ayahBookmark = bookmark(.teal, at: page.firstVerse)
        let pageBookmark = PlacedReadingBookmark(
            id: "page", slot: .orange, placement: .page(page), modifiedOn: .distantPast
        )
        overlays.readingBookmarks = [
            ayahBookmark, pageBookmark,
            bookmark(.red, at: otherPage.firstVerse),
            PlacedReadingBookmark(id: "other-page", slot: .teal, placement: .page(otherPage), modifiedOn: .distantPast),
        ]

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.collectionVerses, [page.firstVerse])
        XCTAssertEqual(restricted.readingBookmarks, [ayahBookmark, pageBookmark])
        XCTAssertEqual(restricted.indicators(for: page.firstVerse), [.collection, .readingBookmark(.teal)])
        XCTAssertTrue(restricted.indicators(for: otherPage.firstVerse).isEmpty)
        XCTAssertEqual(restricted.readingBookmarkSlotsByVerse, [page.firstVerse: [.teal]])
        XCTAssertEqual(restricted.pageReadingBookmarkSlots(on: page), [.orange])
        XCTAssertTrue(restricted.pageReadingBookmarkSlots(on: otherPage).isEmpty)
    }

    func test_annotationTypes_combinesBadgesWithoutTreatingHighlightsOrPageBookmarksAsBadges() {
        let page = Quran.hafsMadani1405.pages[0]
        let verse = page.firstVerse
        var overlays = VerseOverlays()
        overlays.notedVerses = [verse]
        overlays.collectionVerses = [verse]
        overlays.colorHighlights = [page.verses[1]: .green]
        overlays.readingBookmarks = [
            bookmark(.teal, at: verse), bookmark(.orange, at: verse),
            PlacedReadingBookmark(id: "page", slot: .red, placement: .page(page), modifiedOn: .distantPast),
        ]

        XCTAssertEqual(overlays.indicators(for: verse), [.note, .collection, .readingBookmark(.teal), .readingBookmark(.orange)])
        XCTAssertTrue(overlays.indicators(for: page.verses[1]).isEmpty)
        XCTAssertEqual(overlays.readingBookmarkSlotsByVerse, [verse: [.teal, .orange]])
    }

    func test_renamingBookmark_preservesAnnotationWithoutScrolling() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var original = VerseOverlays()
        original.readingBookmarks = [bookmark(.teal, at: ayah)]
        var renamed = original
        renamed.readingBookmarks = [bookmark(.teal, at: ayah, name: "Hifz")]

        XCTAssertEqual(renamed.readingBookmarkSlotsByVerse, [ayah: [.teal]])
        XCTAssertNotEqual(renamed, original)
        XCTAssertFalse(renamed.needsScrolling(comparingTo: original))
        renamed.readingBookmarks = [bookmark(.teal, at: ayah)]
        XCTAssertEqual(renamed.readingBookmarkSlotsByVerse, original.readingBookmarkSlotsByVerse)
    }

    func test_annotations_preserveAllPinsAndOtherTypesOnTheSameAyah() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var overlays = VerseOverlays()
        overlays.notedVerses = [ayah]
        overlays.collectionVerses = [ayah]
        overlays.readingBookmarks = ReadingBookmarkSlot.allCases.map { bookmark($0, at: ayah) }

        XCTAssertEqual(overlays.indicators(for: ayah), [
            .readingBookmark(.teal), .readingBookmark(.orange),
            .readingBookmark(.red), .collection, .note,
        ])
        XCTAssertEqual(overlays.readingBookmarkSlotsByVerse, [ayah: ReadingBookmarkSlot.allCases])
    }

    func test_readingBookmarkSlots_followSlotOrderWhateverTheBookmarkOrder() {
        let page = Quran.hafsMadani1405.pages[1]
        var overlays = VerseOverlays()
        overlays.readingBookmarks = [
            bookmark(.red, at: page.firstVerse),
            PlacedReadingBookmark(id: "page-red", slot: .red, placement: .page(page), modifiedOn: .distantPast),
            bookmark(.teal, at: page.firstVerse),
            PlacedReadingBookmark(id: "page-teal", slot: .teal, placement: .page(page), modifiedOn: .distantPast),
        ]

        XCTAssertEqual(overlays.readingBookmarkSlotsByVerse, [page.firstVerse: [.teal, .red]])
        XCTAssertEqual(overlays.pageReadingBookmarkSlots(on: page), [.teal, .red])
    }

    func test_movingAndClearingPins_preservesOtherAnnotations() {
        let first = Quran.hafsMadani1405.suras[1].verses[4]
        let second = Quran.hafsMadani1405.suras[1].verses[5]
        var overlays = VerseOverlays()
        overlays.notedVerses = [first]
        overlays.readingBookmarks = [bookmark(.teal, at: first), bookmark(.orange, at: first)]

        overlays.readingBookmarks = [bookmark(.teal, at: second)]

        XCTAssertEqual(overlays.indicators(for: first), [.note])
        XCTAssertEqual(overlays.indicators(for: second), [.readingBookmark(.teal)])
        XCTAssertEqual(overlays.readingBookmarkSlotsByVerse, [second: [.teal]])
    }

    func test_annotationChanges_doNotScrollTheReader() {
        let original = VerseOverlays()
        var updated = original
        updated.notedVerses = [Quran.hafsMadani1405.suras[1].verses[4]]

        XCTAssertFalse(updated.needsScrolling(comparingTo: original))
        XCTAssertNil(updated.verseToScrollTo(comparingTo: original))
    }

    func test_pageBookmarks_areExposedForThePageRibbonOnly() {
        let page = Quran.hafsMadani1405.pages[0]
        var overlays = VerseOverlays()
        overlays.readingBookmarks = [PlacedReadingBookmark(
            id: "teal", slot: .teal, placement: .page(page),
            modifiedOn: .distantPast, name: "Hifz"
        )]

        XCTAssertTrue(overlays.readingBookmarkSlotsByVerse.isEmpty)
        XCTAssertTrue(overlays.indicators(for: page.firstVerse).isEmpty)
        XCTAssertEqual(overlays.pageReadingBookmarkSlots(on: page), [.teal])
        XCTAssertTrue(overlays.pageReadingBookmarkSlots(on: Quran.hafsMadani1405.pages[1]).isEmpty)
    }

    func test_readingBookmarkIndicators_hideNotesAndCollections() {
        let noted = Quran.hafsMadani1405.suras[1].verses[4]
        let bookmarked = Quran.hafsMadani1405.suras[1].verses[5]
        var overlays = VerseOverlays()
        overlays.indicatorVisibility = .readingBookmark
        overlays.notedVerses = [noted, bookmarked]
        overlays.collectionVerses = [noted, bookmarked]
        overlays.readingBookmarks = [bookmark(.teal, at: bookmarked)]

        XCTAssertTrue(overlays.indicators(for: noted).isEmpty)
        XCTAssertEqual(overlays.indicators(for: bookmarked), [.readingBookmark(.teal)])
        XCTAssertEqual(overlays.readingBookmarkSlotsByVerse, [bookmarked: [.teal]])
    }

    func test_readingBookmarkSlots_neverIncludeNotesOrCollections() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var overlays = VerseOverlays()
        overlays.notedVerses = [ayah]
        overlays.collectionVerses = [ayah]

        XCTAssertEqual(overlays.indicators(for: ayah), [.note, .collection])
        XCTAssertTrue(overlays.readingBookmarkSlotsByVerse.isEmpty)
    }

    func test_noIndicators_hideEveryAnnotation() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var overlays = VerseOverlays()
        overlays.indicatorVisibility = .none
        overlays.notedVerses = [ayah]
        overlays.collectionVerses = [ayah]
        overlays.readingBookmarks = [
            bookmark(.teal, at: ayah),
            PlacedReadingBookmark(id: "page", slot: .red, placement: .page(ayah.page), modifiedOn: .distantPast),
        ]

        XCTAssertTrue(overlays.indicators(for: ayah).isEmpty)
        XCTAssertTrue(overlays.readingBookmarkSlotsByVerse.isEmpty)
        XCTAssertTrue(overlays.pageReadingBookmarkSlots(on: ayah.page).isEmpty)
    }

    func test_restricted_keepsAyahIndicators() {
        var overlays = VerseOverlays()
        overlays.indicatorVisibility = .none

        XCTAssertEqual(overlays.restricted(to: Quran.hafsMadani1405.pages[0]).indicatorVisibility, .none)
    }

    private func bookmark(_ slot: ReadingBookmarkSlot, at ayah: AyahNumber, name: String? = nil) -> PlacedReadingBookmark {
        PlacedReadingBookmark(id: "\(slot)", slot: slot, placement: .ayah(ayah), modifiedOn: .distantPast, name: name)
    }
}
#endif
