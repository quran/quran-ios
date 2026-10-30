import QuranAnnotations
import QuranKit
import UIKit
import XCTest
@testable import NoorUI

final class VerseOverlaysThemeTests: XCTestCase {
    func testNavigationHighlightPaintsOverTheSavedColor() {
        let verse = Quran.hafsMadani1405.firstVerse
        var overlays = VerseOverlays()
        overlays.colorHighlights = [verse: .green]
        overlays.navigationHighlight = verse

        XCTAssertEqual(overlays.versesByHighlights(), [verse: VerseOverlays.navigationColor])
    }

    func testNavigationTargetAloneDoesNotPaint() {
        let verse = Quran.hafsMadani1405.firstVerse
        var overlays = VerseOverlays()
        overlays.colorHighlights = [verse: .green]
        overlays.navigationTarget = verse

        let colors = overlays.versesByHighlights()
        XCTAssertEqual(Set(colors.keys), [verse])
        XCTAssertEqual(
            colors[verse].map(resolved),
            resolved(HighlightColor.green.uiColor.withAlphaComponent(VerseOverlays.opacity))
        )
    }

    func testPlaybackAndSelectionPaintOverTheNavigationHighlight() {
        let verses = Quran.hafsMadani1405.pages[0].verses
        var overlays = VerseOverlays()
        overlays.navigationHighlight = verses[0]
        overlays.playingVerses = [verses[0]]
        overlays.selectedVerses = [verses[1]]
        overlays.colorHighlights = [verses[1]: .blue]

        XCTAssertEqual(overlays.versesByHighlights(), [
            verses[0]: VerseOverlays.playingColor,
            verses[1]: VerseOverlays.selectionColor,
        ])
    }

    private func resolved(_ color: UIColor) -> UIColor {
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }
}
