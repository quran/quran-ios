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

    func test_underlineLayout_centersAThinBarJustBelowTheMarker() throws {
        let marker = CGRect(x: 100, y: 200, width: 40, height: 40)

        let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: marker, count: 1)

        XCTAssertEqual(layout.underlineFrames.count, 1)
        let underline = try XCTUnwrap(layout.underlineFrames.first)
        XCTAssertEqual(underline.midX, marker.midX, accuracy: 0.001)
        XCTAssertLessThanOrEqual(underline.width, marker.width)
        XCTAssertLessThan(underline.height, marker.height / 4)
        XCTAssertGreaterThan(underline.minY, marker.maxY)
        XCTAssertLessThan(underline.minY - marker.maxY, marker.height / 2)
        XCTAssertEqual(layout.hitFrame, marker.union(underline))
    }

    func test_underlineLayout_stacksEachBookmarkBelowThePreviousOne() {
        let marker = CGRect(x: 0, y: 0, width: 20, height: 20)

        let frames = AyahReadingBookmarkUnderlineLayout(markerFrame: marker, count: 3).underlineFrames

        XCTAssertEqual(frames.count, 3)
        for (upper, lower) in zip(frames, frames.dropFirst()) {
            XCTAssertGreaterThan(lower.minY, upper.maxY)
            XCTAssertEqual(lower.midX, upper.midX)
            XCTAssertEqual(lower.size, upper.size)
        }
    }

    func test_underlineLayout_scalesWithTheMarkerAndKeepsAVisibleMinimum() throws {
        let small = AyahReadingBookmarkUnderlineLayout(markerFrame: CGRect(x: 0, y: 0, width: 10, height: 10), count: 1)
        let large = AyahReadingBookmarkUnderlineLayout(markerFrame: CGRect(x: 0, y: 0, width: 60, height: 60), count: 1)
        let smallUnderline = try XCTUnwrap(small.underlineFrames.first)
        let largeUnderline = try XCTUnwrap(large.underlineFrames.first)

        XCTAssertGreaterThanOrEqual(smallUnderline.height, 2)
        XCTAssertEqual(largeUnderline.width, 6 * smallUnderline.width, accuracy: 0.001)
        XCTAssertGreaterThan(largeUnderline.height, smallUnderline.height)
    }

    func test_underlineLayout_withoutBookmarks_coversOnlyTheMarker() {
        let marker = CGRect(x: 10, y: 10, width: 30, height: 30)

        let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: marker, count: 0)

        XCTAssertTrue(layout.underlineFrames.isEmpty)
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
