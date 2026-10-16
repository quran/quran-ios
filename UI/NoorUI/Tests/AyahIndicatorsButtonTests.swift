#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class AyahIndicatorsButtonTests: XCTestCase {
    func test_accessibilityLabel_identifiesAyahAndAllIndicatorTypes() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[254]
        let button = AyahIndicatorsButton(
            ayah: ayah,
            indicators: [.note, .readingBookmark(.teal), .collection],
            size: 12,
            action: { _ in }
        )

        XCTAssertEqual(button.accessibilityLabel, "Al-Baqarah, Ayah 255; Reading Bookmark: Teal; Collections; Notes")
    }

    func test_smallMarker_hasAtLeast44PointLayout() {
        let button = AyahIndicatorsButton(
            ayah: Quran.hafsMadani1405.suras[1].verses[4],
            indicators: [.note],
            size: 8,
            action: { _ in }
        )
        let controller = UIHostingController(rootView: button.fixedSize())

        let size = controller.sizeThatFits(in: CGSize(width: 390, height: 800))

        XCTAssertGreaterThanOrEqual(size.width, 44)
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func test_markerIndicators_stackEveryReadingBookmarkAndHideNotesAndCollections() {
        let indicators: Set<AyahIndicator> = [.note, .collection, .readingBookmark(.orange), .readingBookmark(.teal)]

        XCTAssertEqual(indicators.markerIndicators, [.readingBookmark(.teal), .readingBookmark(.orange)])
    }

    func test_markerIndicators_preferNoteOverCollection() {
        XCTAssertEqual(Set<AyahIndicator>([.collection, .note]).markerIndicators, [.note])
        XCTAssertEqual(Set<AyahIndicator>([.collection]).markerIndicators, [.collection])
        XCTAssertEqual(Set<AyahIndicator>().markerIndicators, [])
    }

    func test_accessibilityLabel_listsIndicatorsTheMarkerHides() {
        let button = AyahIndicatorsButton(
            ayah: Quran.hafsMadani1405.suras[1].verses[4],
            indicators: [.collection, .note],
            size: 12,
            action: { _ in }
        )

        XCTAssertEqual(button.accessibilityLabel, "Al-Baqarah, Ayah 5; Collections; Notes")
    }

    func test_readingPins_useSlotAccessibleNames() {
        let teal = AyahIndicator.readingBookmark(.teal)
        let orange = AyahIndicator.readingBookmark(.orange)
        let indicators: Set<AyahIndicator> = [orange, .note, teal]

        XCTAssertEqual(indicators.ordered, [teal, orange, .note])
        XCTAssertEqual(teal.accessibilityLabel, "Reading Bookmark: Teal")
    }

    func test_readingPins_haveStableOrderAndDistinctAccessibleNames() {
        let teal = AyahIndicator.readingBookmark(.teal)
        let orange = AyahIndicator.readingBookmark(.orange)
        let red = AyahIndicator.readingBookmark(.red)
        let indicators: Set<AyahIndicator> = [.note, red, teal, orange]

        XCTAssertEqual(indicators.ordered, [teal, orange, red, .note])
        XCTAssertEqual(Set(indicators.ordered.map(\.accessibilityLabel)).count, 4)
        XCTAssertTrue(orange.accessibilityLabel.contains(ReadingBookmarkSlot.orange.displayName))
    }
}
#endif
