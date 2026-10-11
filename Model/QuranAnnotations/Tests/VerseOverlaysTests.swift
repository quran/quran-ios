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
        overlays.indicatorsHidden = true

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.playingVerses, [second, first])
        XCTAssertEqual(restricted.selectedVerses, [first, second])
        XCTAssertEqual(restricted.navigationTarget, first)
        XCTAssertEqual(restricted.colorHighlights, [first: .green])
        XCTAssertEqual(restricted.notedVerses, [second])
        XCTAssertEqual(restricted.pointedWord, overlays.pointedWord)
        XCTAssertTrue(restricted.indicatorsHidden)
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
        hidden.indicatorsHidden = true

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

    func test_focusedVerses_areThePlayingVersesWhileFocusModeIsOn() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.focusModeEnabled = true
        overlays.playingVerses = [verses[1], verses[2]]

        XCTAssertEqual(overlays.focusedVerses, [verses[1], verses[2]])
        XCTAssertFalse(overlays.isDimmed(verses[1]))
        XCTAssertFalse(overlays.isDimmed(verses[2]))
        XCTAssertTrue(overlays.isDimmed(verses[0]))
        XCTAssertTrue(overlays.isDimmed(verses[3]))
    }

    func test_focusedVerses_areNilWhileFocusModeIsOff() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.playingVerses = [verses[1]]

        XCTAssertFalse(overlays.focusModeEnabled)
        XCTAssertNil(overlays.focusedVerses)
        XCTAssertFalse(overlays.isDimmed(verses[0]))
        XCTAssertFalse(overlays.isDimmed(verses[1]))
    }

    func test_focusedVerses_areNilWhenNothingIsPlaying() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.focusModeEnabled = true
        overlays.selectedVerses = [verses[1]]
        overlays.navigationTarget = verses[2]

        XCTAssertNil(overlays.focusedVerses)
        XCTAssertFalse(overlays.isDimmed(verses[0]))
        XCTAssertFalse(overlays.isDimmed(verses[1]))
    }

    func test_restricted_keepsFocusOnThePlayingVersesPage() {
        let page = Quran.hafsMadani1405.pages[1]
        let recited = page.verses[1]
        var overlays = VerseOverlays()
        overlays.focusModeEnabled = true
        overlays.playingVerses = [recited]

        let restricted = overlays.restricted(to: page)

        XCTAssertTrue(restricted.focusModeEnabled)
        XCTAssertEqual(restricted.focusedVerses, [recited])
        XCTAssertFalse(restricted.isDimmed(recited))
        XCTAssertTrue(restricted.isDimmed(page.verses[0]))
    }

    func test_restricted_dimsEveryVerseOfAPageWhileAudioPlaysOnAnotherPage() {
        let page = Quran.hafsMadani1405.pages[0]
        let recited = Quran.hafsMadani1405.pages[1].firstVerse
        var overlays = VerseOverlays()
        overlays.focusModeEnabled = true
        overlays.playingVerses = [recited]

        let restricted = overlays.restricted(to: page)

        XCTAssertTrue(restricted.playingVerses.isEmpty)
        XCTAssertEqual(restricted.focusedVerses, [])
        for verse in page.verses {
            XCTAssertTrue(restricted.isDimmed(verse), "\(verse)")
        }
    }

    func test_restricted_dimsNothingWhenFocusModeIsOffOrNothingPlays() {
        let page = Quran.hafsMadani1405.pages[0]
        let recited = Quran.hafsMadani1405.pages[1].firstVerse
        var unfocused = VerseOverlays()
        unfocused.playingVerses = [recited]
        var silent = VerseOverlays()
        silent.focusModeEnabled = true

        let restrictedUnfocused = unfocused.restricted(to: page)
        let restrictedSilent = silent.restricted(to: page)

        XCTAssertNil(restrictedUnfocused.focusedVerses)
        XCTAssertFalse(restrictedUnfocused.isDimmed(page.firstVerse))
        XCTAssertTrue(restrictedSilent.focusModeEnabled)
        XCTAssertNil(restrictedSilent.focusedVerses)
        XCTAssertFalse(restrictedSilent.isDimmed(page.firstVerse))
    }

    func test_focusModeChange_changesEqualityWithoutRequestingScrolling() {
        var original = VerseOverlays()
        original.playingVerses = [Quran.hafsMadani1405.firstVerse]
        var focused = original
        focused.focusModeEnabled = true

        XCTAssertNotEqual(original, focused)
        XCTAssertFalse(focused.needsScrolling(comparingTo: original))
        XCTAssertNil(focused.verseToScrollTo(comparingTo: original))
    }
}
