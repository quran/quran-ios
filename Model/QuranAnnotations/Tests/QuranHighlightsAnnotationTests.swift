#if QURAN_SYNC
import QuranKit
import XCTest
@testable import QuranAnnotations

final class QuranHighlightsAnnotationTests: XCTestCase {
    func test_renamingBookmark_preservesAnnotationWithoutScrolling() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var original = QuranHighlights()
        original.readingBookmarks = [bookmark(.coral, at: ayah)]
        var renamed = original
        renamed.readingBookmarks = [bookmark(.coral, at: ayah, name: "Hifz")]

        XCTAssertEqual(renamed.annotationsByVerse, [ayah: [.readingBookmark(.coral)]])
        XCTAssertNotEqual(renamed, original)
        XCTAssertFalse(renamed.needsScrolling(comparingTo: original))
        renamed.readingBookmarks = [bookmark(.coral, at: ayah)]
        XCTAssertEqual(renamed.annotationsByVerse, original.annotationsByVerse)
    }

    func test_annotations_preserveAllPinsAndOtherTypesOnTheSameAyah() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        var highlights = QuranHighlights()
        highlights.noteVerses = [ayah]
        highlights.collectionVerses = [ayah]
        highlights.readingBookmarks = ReadingBookmarkSlot.allCases.map { bookmark($0, at: ayah) }

        XCTAssertEqual(highlights.annotationsByVerse, [ayah: [
            .readingBookmark(.coral), .readingBookmark(.teal),
            .readingBookmark(.indigo), .collection, .note,
        ]])
    }

    func test_movingAndClearingPins_preservesOtherAnnotations() {
        let first = Quran.hafsMadani1405.suras[1].verses[4]
        let second = Quran.hafsMadani1405.suras[1].verses[5]
        var highlights = QuranHighlights()
        highlights.noteVerses = [first]
        highlights.readingBookmarks = [bookmark(.coral, at: first), bookmark(.teal, at: first)]

        highlights.readingBookmarks = [bookmark(.coral, at: second)]

        XCTAssertEqual(highlights.annotationsByVerse, [first: [.note], second: [.readingBookmark(.coral)]])
    }

    func test_annotationChanges_doNotScrollTheReader() {
        let original = QuranHighlights()
        var updated = original
        updated.noteVerses = [Quran.hafsMadani1405.suras[1].verses[4]]

        XCTAssertFalse(updated.needsScrolling(comparingTo: original))
        XCTAssertNil(updated.verseToScrollTo(comparingTo: original))
    }

    func test_pageBookmarks_doNotProduceAyahAnnotations() {
        var highlights = QuranHighlights()
        highlights.readingBookmarks = [PlacedReadingBookmark(
            id: "coral", slot: .coral, placement: .page(Quran.hafsMadani1405.pages[0]),
            modifiedOn: .distantPast, name: "Hifz"
        )]

        XCTAssertTrue(highlights.annotationsByVerse.isEmpty)
    }

    private func bookmark(_ slot: ReadingBookmarkSlot, at ayah: AyahNumber, name: String? = nil) -> PlacedReadingBookmark {
        PlacedReadingBookmark(id: "\(slot)", slot: slot, placement: .ayah(ayah), modifiedOn: .distantPast, name: name)
    }
}
#endif
