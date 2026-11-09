import QuranAnnotations
import XCTest
@testable import NoorUI

final class HighlightColorThemeTests: XCTestCase {
    func test_sortedByUsage_putsTheMostUsedFirstAndBreaksTiesAlphabetically() {
        let colors = HighlightColor.sortedByUsage(in: [.purple, .yellow, .purple, .pink])

        XCTAssertEqual(colors, [.purple] + alphabetical([.pink, .yellow]) + alphabetical([.blue, .green]))
    }

    // MARK: Private

    private func alphabetical(_ colors: [HighlightColor]) -> [HighlightColor] {
        colors.sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }
}
