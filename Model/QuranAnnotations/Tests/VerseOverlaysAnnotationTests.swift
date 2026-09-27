#if QURAN_SYNC
import QuranKit
import XCTest
@testable import QuranAnnotations

final class VerseOverlaysAnnotationTests: XCTestCase {
    func test_restricted_keepsCollectionsAndBothBookmarkPlacementsOnThePage() {
        let page = Quran.hafsMadani1405.pages[0]
        let otherPage = Quran.hafsMadani1405.pages[1]
        var overlays = VerseOverlays()
        overlays.collectionVerses = [page.firstVerse, otherPage.firstVerse]
        let ayahBookmark = bookmark(.green, at: page.firstVerse)
        let pageBookmark = PlacedReadingBookmark(
            id: "page", slot: .purple, placement: .page(page), modifiedOn: .distantPast
        )
        overlays.readingBookmarks = [
            ayahBookmark, pageBookmark,
            bookmark(.blue, at: otherPage.firstVerse),
            PlacedReadingBookmark(id: "other-page", slot: .green, placement: .page(otherPage), modifiedOn: .distantPast),
        ]

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.collectionVerses, [page.firstVerse])
        XCTAssertEqual(restricted.readingBookmarks, [ayahBookmark, pageBookmark])
        XCTAssertEqual(restricted.annotationTypes(for: page.firstVerse), [.collection, .readingBookmark(.green)])
        XCTAssertTrue(restricted.annotationTypes(for: otherPage.firstVerse).isEmpty)
    }

    func test_annotationTypes_combinesBadgesWithoutTreatingHighlightsOrPageBookmarksAsBadges() {
        let page = Quran.hafsMadani1405.pages[0]
        let verse = page.firstVerse
        var overlays = VerseOverlays()
        overlays.notedVerses = [verse]
        overlays.collectionVerses = [verse]
        overlays.colorHighlights = [page.verses[1]: .green]
        overlays.readingBookmarks = [
            bookmark(.green, at: verse), bookmark(.purple, at: verse),
            PlacedReadingBookmark(id: "page", slot: .blue, placement: .page(page), modifiedOn: .distantPast),
        ]

        XCTAssertEqual(overlays.annotationTypes(for: verse), [.note, .collection, .readingBookmark(.green), .readingBookmark(.purple)])
        XCTAssertTrue(overlays.annotationTypes(for: page.verses[1]).isEmpty)
        XCTAssertEqual(overlays.annotationsByVerse, [verse: overlays.annotationTypes(for: verse)])
    }

    func test_renamingBookmark_preservesAnnotationWithoutScrolling() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var original = VerseOverlays()
        original.readingBookmarks = [bookmark(.green, at: ayah)]
        var renamed = original
        renamed.readingBookmarks = [bookmark(.green, at: ayah, name: "Hifz")]

        XCTAssertEqual(renamed.annotationsByVerse, [ayah: [.readingBookmark(.green)]])
        XCTAssertNotEqual(renamed, original)
        XCTAssertFalse(renamed.needsScrolling(comparingTo: original))
        renamed.readingBookmarks = [bookmark(.green, at: ayah)]
        XCTAssertEqual(renamed.annotationsByVerse, original.annotationsByVerse)
    }

    func test_annotations_preserveAllPinsAndOtherTypesOnTheSameAyah() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var overlays = VerseOverlays()
        overlays.notedVerses = [ayah]
        overlays.collectionVerses = [ayah]
        overlays.readingBookmarks = ReadingBookmarkSlot.allCases.map { bookmark($0, at: ayah) }

        XCTAssertEqual(overlays.annotationsByVerse, [ayah: [
            .readingBookmark(.green), .readingBookmark(.purple),
            .readingBookmark(.blue), .collection, .note,
        ]])
    }

    func test_movingAndClearingPins_preservesOtherAnnotations() {
        let first = Quran.hafsMadani1405.suras[1].verses[4]
        let second = Quran.hafsMadani1405.suras[1].verses[5]
        var overlays = VerseOverlays()
        overlays.notedVerses = [first]
        overlays.readingBookmarks = [bookmark(.green, at: first), bookmark(.purple, at: first)]

        overlays.readingBookmarks = [bookmark(.green, at: second)]

        XCTAssertEqual(overlays.annotationsByVerse, [first: [.note], second: [.readingBookmark(.green)]])
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
            id: "green", slot: .green, placement: .page(Quran.hafsMadani1405.pages[0]),
            modifiedOn: .distantPast, name: "Hifz"
        )]

        XCTAssertTrue(overlays.annotationsByVerse.isEmpty)
    }

    private func bookmark(_ slot: ReadingBookmarkSlot, at ayah: AyahNumber, name: String? = nil) -> PlacedReadingBookmark {
        PlacedReadingBookmark(id: "\(slot)", slot: slot, placement: .ayah(ayah), modifiedOn: .distantPast, name: name)
    }
}
#endif
