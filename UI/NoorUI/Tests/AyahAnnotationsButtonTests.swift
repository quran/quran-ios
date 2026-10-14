#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class AyahAnnotationsButtonTests: XCTestCase {
    func test_accessibilityLabel_identifiesAyahAndAllAnnotationTypes() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[254]
        let button = AyahAnnotationsButton(
            ayah: ayah,
            annotations: [.note, .readingBookmark(.teal), .collection],
            height: 12,
            action: { _ in }
        )

        XCTAssertEqual(button.accessibilityLabel, "Al-Baqarah, Ayah 255; Reading Bookmark: Teal; Collections; Notes")
    }

    func test_smallBadge_hasAtLeast44PointLayout() {
        let button = AyahAnnotationsButton(
            ayah: Quran.hafsMadani1405.suras[1].verses[4],
            annotations: [.note],
            height: 8,
            action: { _ in }
        )
        let controller = UIHostingController(rootView: button.fixedSize())

        let size = controller.sizeThatFits(in: CGSize(width: 390, height: 800))

        XCTAssertGreaterThanOrEqual(size.width, 44)
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func test_readingPins_useSlotAccessibleNames() {
        let teal = AyahAnnotation.readingBookmark(.teal)
        let orange = AyahAnnotation.readingBookmark(.orange)
        let annotations: Set<AyahAnnotation> = [orange, .note, teal]

        XCTAssertEqual(annotations.ordered, [teal, orange, .note])
        XCTAssertEqual(teal.accessibilityLabel, "Reading Bookmark: Teal")
    }

    func test_readingPins_haveStableOrderAndDistinctAccessibleNames() {
        let teal = AyahAnnotation.readingBookmark(.teal)
        let orange = AyahAnnotation.readingBookmark(.orange)
        let red = AyahAnnotation.readingBookmark(.red)
        let annotations: Set<AyahAnnotation> = [.note, red, teal, orange]

        XCTAssertEqual(annotations.ordered, [teal, orange, red, .note])
        XCTAssertEqual(Set(annotations.ordered.map(\.accessibilityLabel)).count, 4)
        XCTAssertTrue(orange.accessibilityLabel.contains(ReadingBookmarkSlot.orange.displayName))
    }
}
#endif
