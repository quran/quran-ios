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
        let coral = AyahAnnotation.readingBookmark(.coral)
        let teal = AyahAnnotation.readingBookmark(.teal)
        let annotations: Set<AyahAnnotation> = [teal, .note, coral]

        XCTAssertEqual(annotations.ordered, [coral, teal, .note])
        XCTAssertEqual(coral.accessibilityLabel, "\(l("ayah.menu.reading-bookmark.title")), \(ReadingBookmarkSlot.coral.displayName)")
    }

    func test_readingPins_haveStableOrderAndDistinctAccessibleNames() {
        let coral = AyahAnnotation.readingBookmark(.coral)
        let teal = AyahAnnotation.readingBookmark(.teal)
        let indigo = AyahAnnotation.readingBookmark(.indigo)
        let annotations: Set<AyahAnnotation> = [.note, indigo, coral, teal]

        XCTAssertEqual(annotations.ordered, [coral, teal, indigo, .note])
        XCTAssertEqual(Set(annotations.ordered.map(\.accessibilityLabel)).count, 4)
        XCTAssertTrue(teal.accessibilityLabel.contains(ReadingBookmarkSlot.teal.displayName))
    }
}
#endif
