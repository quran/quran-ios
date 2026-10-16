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
        XCTAssertEqual(overlays.indicatorsByVerse, [verse: overlays.indicators(for: verse)])
    }

    func test_renamingBookmark_preservesAnnotationWithoutScrolling() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var original = VerseOverlays()
        original.readingBookmarks = [bookmark(.teal, at: ayah)]
        var renamed = original
        renamed.readingBookmarks = [bookmark(.teal, at: ayah, name: "Hifz")]

        XCTAssertEqual(renamed.indicatorsByVerse, [ayah: [.readingBookmark(.teal)]])
        XCTAssertNotEqual(renamed, original)
        XCTAssertFalse(renamed.needsScrolling(comparingTo: original))
        renamed.readingBookmarks = [bookmark(.teal, at: ayah)]
        XCTAssertEqual(renamed.indicatorsByVerse, original.indicatorsByVerse)
    }

    func test_annotations_preserveAllPinsAndOtherTypesOnTheSameAyah() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var overlays = VerseOverlays()
        overlays.notedVerses = [ayah]
        overlays.collectionVerses = [ayah]
        overlays.readingBookmarks = ReadingBookmarkSlot.allCases.map { bookmark($0, at: ayah) }

        XCTAssertEqual(overlays.indicatorsByVerse, [ayah: [
            .readingBookmark(.teal), .readingBookmark(.orange),
            .readingBookmark(.red), .collection, .note,
        ]])
    }

    func test_movingAndClearingPins_preservesOtherAnnotations() {
        let first = Quran.hafsMadani1405.suras[1].verses[4]
        let second = Quran.hafsMadani1405.suras[1].verses[5]
        var overlays = VerseOverlays()
        overlays.notedVerses = [first]
        overlays.readingBookmarks = [bookmark(.teal, at: first), bookmark(.orange, at: first)]

        overlays.readingBookmarks = [bookmark(.teal, at: second)]

        XCTAssertEqual(overlays.indicatorsByVerse, [first: [.note], second: [.readingBookmark(.teal)]])
    }

    func test_annotationChanges_doNotScrollTheReader() {
        let original = VerseOverlays()
        var updated = original
        updated.notedVerses = [Quran.hafsMadani1405.suras[1].verses[4]]

        XCTAssertFalse(updated.needsScrolling(comparingTo: original))
        XCTAssertNil(updated.verseToScrollTo(comparingTo: original))
    }

    func test_pageBookmarks_doNotProduceAyahAnnotations() {
        var overlays = VerseOverlays()
        overlays.readingBookmarks = [PlacedReadingBookmark(
            id: "teal", slot: .teal, placement: .page(Quran.hafsMadani1405.pages[0]),
            modifiedOn: .distantPast, name: "Hifz"
        )]

        XCTAssertTrue(overlays.indicatorsByVerse.isEmpty)
    }

    func test_readingBookmarkIndicators_hideNotesAndCollections() {
        let noted = Quran.hafsMadani1405.suras[1].verses[4]
        let bookmarked = Quran.hafsMadani1405.suras[1].verses[5]
        var overlays = VerseOverlays()
        overlays.indicatorVisibility = .readingBookmark
        overlays.notedVerses = [noted, bookmarked]
        overlays.collectionVerses = [noted]
        overlays.readingBookmarks = [bookmark(.teal, at: bookmarked)]

        XCTAssertTrue(overlays.indicators(for: noted).isEmpty)
        XCTAssertEqual(overlays.indicators(for: bookmarked), [.readingBookmark(.teal)])
        XCTAssertEqual(overlays.indicatorsByVerse, [bookmarked: [.readingBookmark(.teal)]])
    }

    func test_noIndicators_hideEveryAnnotation() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var overlays = VerseOverlays()
        overlays.indicatorVisibility = .none
        overlays.notedVerses = [ayah]
        overlays.collectionVerses = [ayah]
        overlays.readingBookmarks = [bookmark(.teal, at: ayah)]

        XCTAssertTrue(overlays.indicators(for: ayah).isEmpty)
        XCTAssertTrue(overlays.indicatorsByVerse.isEmpty)
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
