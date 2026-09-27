#if QURAN_SYNC
import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class AyahAnnotationsButtonTests: XCTestCase {
    func test_accessibilityLabel_identifiesAyahAndAllAnnotationTypes() {
        let ayah = Quran.hafsMadani1405.suras[1].verses[4]
        let button = AyahAnnotationsButton(ayah: ayah, annotations: [.note, .collection], height: 12, action: { _ in })

        XCTAssertEqual(button.accessibilityLabel, "\(ayah.localizedName), \(l("bookmarks.collections")), \(l("tab.notes"))")
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
        let green = AyahAnnotation.readingBookmark(.green)
        let purple = AyahAnnotation.readingBookmark(.purple)
        let annotations: Set<AyahAnnotation> = [purple, .note, green]

        XCTAssertEqual(annotations.ordered, [green, purple, .note])
        XCTAssertEqual(green.accessibilityLabel, "\(l("ayah.menu.reading-bookmark.title")), \(ReadingBookmarkSlot.green.displayName)")
    }

    func test_readingPins_haveStableOrderAndDistinctAccessibleNames() {
        let green = AyahAnnotation.readingBookmark(.green)
        let purple = AyahAnnotation.readingBookmark(.purple)
        let blue = AyahAnnotation.readingBookmark(.blue)
        let annotations: Set<AyahAnnotation> = [.note, blue, green, purple]

        XCTAssertEqual(annotations.ordered, [green, purple, blue, .note])
        XCTAssertEqual(Set(annotations.ordered.map(\.accessibilityLabel)).count, 4)
        XCTAssertTrue(purple.accessibilityLabel.contains(ReadingBookmarkSlot.purple.displayName))
    }
}
#endif
