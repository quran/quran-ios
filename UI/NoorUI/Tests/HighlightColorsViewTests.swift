import QuranAnnotations
import XCTest
@testable import NoorUI

final class HighlightColorsViewTests: XCTestCase {
    func test_compactCount_keepsSmallCountsAndShortensThousands() {
        let english = Locale(identifier: "en_US")

        XCTAssertEqual(HighlightColorsView.compactCount(0, locale: english), "0")
        XCTAssertEqual(HighlightColorsView.compactCount(128, locale: english), "128")
        XCTAssertEqual(HighlightColorsView.compactCount(999, locale: english), "999")
        XCTAssertEqual(HighlightColorsView.compactCount(1204, locale: english), "1.2K")
        XCTAssertEqual(HighlightColorsView.compactCount(15000, locale: english), "15K")
    }

    func test_sortedByUsage_putsTheMostUsedFirstAndBreaksTiesAlphabetically() {
        let colors = HighlightColor.sortedByUsage(in: [.purple, .yellow, .purple, .pink])

        XCTAssertEqual(colors, [.purple] + alphabetical([.pink, .yellow]) + alphabetical([.blue, .green]))
    }

    private func alphabetical(_ colors: [HighlightColor]) -> [HighlightColor] {
        colors.sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }
}
