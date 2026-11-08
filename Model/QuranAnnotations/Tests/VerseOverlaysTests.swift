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
        overlays.navigationHighlight = second
        overlays.colorHighlights = [first: .green, other: .blue]
        overlays.notedVerses = [second, other]
        overlays.pointedWord = Word(verse: second, wordNumber: 1)

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.playingVerses, [second, first])
        XCTAssertEqual(restricted.selectedVerses, [first, second])
        XCTAssertEqual(restricted.navigationTarget, first)
        XCTAssertEqual(restricted.navigationHighlight, second)
        XCTAssertEqual(restricted.colorHighlights, [first: .green])
        XCTAssertEqual(restricted.notedVerses, [second])
        XCTAssertEqual(restricted.pointedWord, overlays.pointedWord)
        XCTAssertEqual(overlays.playingVerses, [second, other, first])
    }

    func test_restricted_removesNavigationTargetAndPointedWordFromAnotherPage() {
        let page = Quran.hafsMadani1405.pages[0]
        let other = Quran.hafsMadani1405.pages[1].firstVerse
        var overlays = VerseOverlays()
        overlays.navigationTarget = other
        overlays.navigationHighlight = other
        overlays.pointedWord = Word(verse: other, wordNumber: 1)

        let restricted = overlays.restricted(to: page)

        XCTAssertNil(restricted.navigationTarget)
        XCTAssertNil(restricted.navigationHighlight)
        XCTAssertNil(restricted.pointedWord)
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

    func test_needsScrolling_onlyForANewNavigationTarget() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        let original = VerseOverlays()
        var targeted = original
        targeted.navigationTarget = verses[0]
        var retargeted = targeted
        retargeted.navigationTarget = verses[1]
        var consumed = retargeted
        consumed.navigationTarget = nil

        XCTAssertTrue(targeted.needsScrolling(comparingTo: original))
        XCTAssertTrue(retargeted.needsScrolling(comparingTo: targeted))
        XCTAssertFalse(consumed.needsScrolling(comparingTo: retargeted))
    }

    func test_needsScrolling_ignoresTheNavigationHighlight() {
        let original = VerseOverlays()
        var highlighted = original
        highlighted.navigationHighlight = Quran.hafsMadani1405.firstVerse

        XCTAssertFalse(highlighted.needsScrolling(comparingTo: original))
        XCTAssertFalse(original.needsScrolling(comparingTo: highlighted))
    }

    func test_pageNavigation_prefersLastSelectedVerseOverLastPlayingVerse() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        let original = VerseOverlays()
        var updated = original
        updated.playingVerses = [verses[0], verses[1]]
        updated.selectedVerses = [verses[2], verses[3]]

        XCTAssertEqual(updated.verseToScrollTo(comparingTo: original), verses[3])
    }

    // MARK: Dim Other Ayahs

    func test_undimmedVerses_areThePlayingVersesWhileDimmingOtherAyahs() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [verses[1], verses[2]]

        XCTAssertEqual(overlays.undimmedVerses, [verses[1], verses[2]])
    }

    func test_undimmedVerses_areNilWhileNotDimmingOtherAyahs() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.playingVerses = [verses[1]]

        XCTAssertNil(overlays.undimmedVerses)
    }

    func test_undimmedVerses_areNilWhenNothingIsPlaying() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.selectedVerses = [verses[1]]
        overlays.navigationHighlight = verses[2]

        XCTAssertNil(overlays.undimmedVerses)
    }

    func test_undimmedVerses_includeTheSelectionDuringPlayback() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [verses[1]]
        overlays.selectedVerses = [verses[3], verses[4]]

        XCTAssertEqual(overlays.undimmedVerses, [verses[1], verses[3], verses[4]])
    }

    func test_undimmedVerses_includeTheNavigationHighlightDuringPlayback() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [verses[1]]
        overlays.navigationHighlight = verses[5]

        XCTAssertEqual(overlays.undimmedVerses, [verses[1], verses[5]])
    }

    func test_undimmedVerses_includeTheWordPointersVerseDuringPlayback() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [verses[1]]
        overlays.pointedWord = Word(verse: verses[4], wordNumber: 2)

        XCTAssertEqual(overlays.undimmedVerses, [verses[1], verses[4]])
    }

    func test_undimmedVerses_leaveOutTheNavigationTarget() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [verses[1]]
        overlays.navigationTarget = verses[5]

        XCTAssertEqual(overlays.undimmedVerses, [verses[1]])
    }

    func test_restricted_keepsThePlayingVerseOnItsPageUndimmed() {
        let page = Quran.hafsMadani1405.pages[1]
        let recited = page.verses[1]
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [recited]

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.undimmedVerses, [recited])
    }

    func test_restricted_dimsEveryVerseOfAPageWhileAudioPlaysOnAnotherPage() {
        let page = Quran.hafsMadani1405.pages[0]
        let recited = Quran.hafsMadani1405.pages[1].firstVerse
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [recited]

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.undimmedVerses, [])
    }

    func test_restricted_keepsTheSelectionUndimmedWhileAudioPlaysOnAnotherPage() {
        let page = Quran.hafsMadani1405.pages[0]
        let selected = page.verses[2]
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true
        overlays.playingVerses = [Quran.hafsMadani1405.pages[1].firstVerse]
        overlays.selectedVerses = [selected]

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted.undimmedVerses, [selected])
    }

    func test_restricted_isUnaffectedByAudioOnAnotherPageWhileNotDimmingOtherAyahs() {
        let page = Quran.hafsMadani1405.pages[0]
        var overlays = VerseOverlays()
        overlays.playingVerses = [Quran.hafsMadani1405.pages[1].firstVerse]

        let restricted = overlays.restricted(to: page)

        XCTAssertEqual(restricted, VerseOverlays())
    }

    func test_restricted_dimsNothingWhenNothingIsPlaying() {
        let page = Quran.hafsMadani1405.pages[0]
        var overlays = VerseOverlays()
        overlays.dimsOtherAyahs = true

        let restricted = overlays.restricted(to: page)

        XCTAssertNil(restricted.undimmedVerses)
    }

    func test_dimsOtherAyahsChange_doesNotRequestScrolling() {
        var original = VerseOverlays()
        original.playingVerses = [Quran.hafsMadani1405.firstVerse]
        var dimming = original
        dimming.dimsOtherAyahs = true

        XCTAssertFalse(dimming.needsScrolling(comparingTo: original))
        XCTAssertNil(dimming.verseToScrollTo(comparingTo: original))
    }
}
