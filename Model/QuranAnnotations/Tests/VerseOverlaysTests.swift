import QuranKit
import XCTest
@testable import QuranAnnotations

final class VerseOverlaysTests: XCTestCase {
    func test_restricted_keepsOnlyThePagesVersesAndPreservesTheirOrder() {
        let page = Quran.hafsMadani1405.pages[0]
        let first = page.verses[0]
        let second = page.verses[1]
        let other = Quran.hafsMadani1405.pages[1].firstVerse
        var overlays = VerseOverlays()
        overlays.playingVerses = [second, other, first]
        overlays.selectedVerses = [other, first, second]
        overlays.navigationTarget = first
        overlays.colorHighlights = [first: .green, other: .blue]
        overlays.notedVerses = [second, other]
        overlays.pointedWord = Word(verse: second, wordNumber: 1)
        overlays.annotationsHidden = true

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.playingVerses, [second, first])
        XCTAssertEqual(restricted.selectedVerses, [first, second])
        XCTAssertEqual(restricted.navigationTarget, first)
        XCTAssertEqual(restricted.colorHighlights, [first: .green])
        XCTAssertEqual(restricted.notedVerses, [second])
        XCTAssertEqual(restricted.pointedWord, overlays.pointedWord)
        XCTAssertTrue(restricted.annotationsHidden)
        XCTAssertEqual(overlays.playingVerses, [second, other, first])
    }

    func test_restricted_removesNavigationTargetAndPointedWordFromAnotherPage() {
        let page = Quran.hafsMadani1405.pages[0]
        let other = Quran.hafsMadani1405.pages[1].firstVerse
        var overlays = VerseOverlays()
        overlays.navigationTarget = other
        overlays.pointedWord = Word(verse: other, wordNumber: 1)

        let restricted = overlays.restricted(to: page)

        XCTAssertNil(restricted.navigationTarget)
        XCTAssertNil(restricted.pointedWord)
    }

    func test_visibilityChange_changesEqualityWithoutRequestingScrolling() {
        let original = VerseOverlays()
        var hidden = original
        hidden.annotationsHidden = true

        XCTAssertNotEqual(original, hidden)
        XCTAssertFalse(hidden.needsScrolling(comparingTo: original))
        XCTAssertNil(hidden.verseToScrollTo(comparingTo: original))
    }

    func test_scrollingTarget_prefersPlayingVerseOverNavigation() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.playingVerses = [verses[0], verses[1]]
        overlays.navigationTarget = verses[2]

        XCTAssertEqual(overlays.firstScrollingVerse(), verses[0])

        overlays.playingVerses = []

        XCTAssertEqual(overlays.firstScrollingVerse(), verses[2])
    }

    func test_pageNavigation_prefersLastSelectedVerseOverLastPlayingVerse() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        let original = VerseOverlays()
        var updated = original
        updated.playingVerses = [verses[0], verses[1]]
        updated.selectedVerses = [verses[2], verses[3]]

        XCTAssertEqual(updated.verseToScrollTo(comparingTo: original), verses[3])
    }
}
