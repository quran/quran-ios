#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class AyahReadingBookmarkIndicatorTests: XCTestCase {
    func test_accessibilityLabel_identifiesAyahAndEveryReadingBookmark() {
        let button = AyahReadingBookmarkButton(
            ayah: Quran.hafsMadani1405.suras[1].verses[254],
            slots: [.teal, .orange],
            size: CGSize(width: 12, height: 12),
            action: { _ in }
        )

        XCTAssertEqual(
            button.accessibilityLabel,
            "Al-Baqarah, Ayah 255; Reading Bookmark: Teal; Reading Bookmark: Orange"
        )
    }

    func test_smallMarker_hasAtLeast44PointLayout() {
        let button = AyahReadingBookmarkButton(
            ayah: Quran.hafsMadani1405.suras[1].verses[4],
            slots: [.teal],
            size: CGSize(width: 8, height: 8),
            action: { _ in }
        )
        let controller = UIHostingController(rootView: button.fixedSize())

        let size = controller.sizeThatFits(in: CGSize(width: 390, height: 800))

        XCTAssertGreaterThanOrEqual(size.width, 44)
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func test_underlineLayout_centersOneThinLineJustBelowAndWiderThanTheMarker() throws {
        let marker = CGRect(x: 100, y: 200, width: 40, height: 40)

        let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: marker, count: 1)

        let line = try XCTUnwrap(layout.lineFrame)
        XCTAssertEqual(line.midX, marker.midX, accuracy: 0.001)
        XCTAssertEqual(line.width, 48, accuracy: 0.001)
        XCTAssertEqual(line.height, 4.8, accuracy: 0.001)
        XCTAssertEqual(line.minY, 246, accuracy: 0.001)
        XCTAssertEqual(layout.hitFrame, marker.union(line))
    }

    func test_underlineLayout_lineDoesNotDependOnTheBookmarkCount() {
        let marker = CGRect(x: 10, y: 20, width: 30, height: 30)

        let layouts = (1 ... 3).map { AyahReadingBookmarkUnderlineLayout(markerFrame: marker, count: $0) }

        XCTAssertEqual(layouts.map(\.lineFrame), Array(repeating: layouts[0].lineFrame, count: 3))
        XCTAssertEqual(layouts.map(\.hitFrame), Array(repeating: layouts[0].hitFrame, count: 3))
        XCTAssertEqual(layouts.map(\.gap), Array(repeating: layouts[0].gap, count: 3))
    }

    func test_underlineLayout_scalesWithTheMarker() throws {
        let small = AyahReadingBookmarkUnderlineLayout(markerFrame: CGRect(x: 0, y: 0, width: 30, height: 30), count: 3)
        let large = AyahReadingBookmarkUnderlineLayout(markerFrame: CGRect(x: 0, y: 0, width: 60, height: 60), count: 3)
        let smallLine = try XCTUnwrap(small.lineFrame)
        let largeLine = try XCTUnwrap(large.lineFrame)

        XCTAssertEqual(largeLine.width, 2 * smallLine.width, accuracy: 0.001)
        XCTAssertEqual(largeLine.height, 2 * smallLine.height, accuracy: 0.001)
        XCTAssertEqual(largeLine.minY, 2 * smallLine.minY, accuracy: 0.001)
        XCTAssertEqual(small.gap, 1.5, accuracy: 0.001)
        XCTAssertEqual(large.gap, 3, accuracy: 0.001)
    }

    func test_underlineLayout_smallMarker_keepsAVisibleHeightAndGap() throws {
        let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: CGRect(x: 0, y: 0, width: 10, height: 10), count: 2)

        let line = try XCTUnwrap(layout.lineFrame)
        XCTAssertEqual(line.height, 2.5, accuracy: 0.001)
        XCTAssertEqual(layout.gap, 1, accuracy: 0.001)
    }

    func test_underlineLayout_tinyMarker_leavesRoomForEverySegment() throws {
        let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: CGRect(x: 0, y: 0, width: 1, height: 1), count: 3)

        let line = try XCTUnwrap(layout.lineFrame)
        XCTAssertGreaterThan(line.width - 2 * layout.gap, 0)
    }

    func test_underlineLayout_zeroSizeMarker_hasNoLine() {
        let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: .zero, count: 3)

        XCTAssertNil(layout.lineFrame)
        XCTAssertEqual(layout.hitFrame, .zero)
    }

    func test_underlineLayout_withoutBookmarks_coversOnlyTheMarker() {
        let marker = CGRect(x: 10, y: 10, width: 30, height: 30)

        let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: marker, count: 0)

        XCTAssertNil(layout.lineFrame)
        XCTAssertEqual(layout.hitFrame, marker)
    }

    func test_bookmarkedMarkers_skipMarkersWithoutReadingBookmarks() {
        let ayahs = Array(Quran.hafsMadani1405.suras[1].verses.prefix(3))
        let markers = ayahs.map { AyahMarkerPlacement(ayah: $0, frame: .zero) }

        let bookmarked = markers.bookmarked(by: [ayahs[0]: [.teal], ayahs[1]: []])

        XCTAssertEqual(bookmarked, [markers[0]])
    }

    func test_pageRibbons_accessibilityLabelNamesThePageAndEverySlot() {
        let ribbons = PageReadingBookmarkRibbons(page: Quran.hafsMadani1405.pages[2], slots: [.teal, .red])

        XCTAssertEqual(ribbons.accessibilityLabel, "Page 3; Reading Bookmark: Teal; Reading Bookmark: Red")
    }

    func test_pageRibbons_stepByAFractionOfTheirWidth() {
        let lengths = PageReadingBookmarkRibbons.ribbonLengths(count: 3, width: 16, available: 59)

        XCTAssertEqual(lengths.count, 3)
        XCTAssertEqual(lengths[0], 44.6, accuracy: 0.001)
        XCTAssertEqual(lengths[1], 51.8, accuracy: 0.001)
        XCTAssertEqual(lengths[2], 59, accuracy: 0.001)
    }

    func test_pageRibbons_wideRibbonsInAShortTopStayDistinct() {
        let lengths = PageReadingBookmarkRibbons.ribbonLengths(count: 3, width: 40, available: 32)

        XCTAssertEqual(lengths.count, 3)
        XCTAssertEqual(lengths[0], 16, accuracy: 0.001)
        XCTAssertEqual(lengths[1], 24, accuracy: 0.001)
        XCTAssertEqual(lengths[2], 32, accuracy: 0.001)
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
