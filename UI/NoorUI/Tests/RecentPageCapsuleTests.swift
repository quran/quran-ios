import Localization
import QuranKit
import XCTest
@testable import NoorUI

@MainActor
final class RecentPageCapsuleTests: XCTestCase {
    func test_accessibilityLabel_separatesSurasPageAndDateWithTheListSeparator() {
        let page = Quran.hafsMadani1405.pages.last!
        let timestamp = "Monday, October 14, 2026"
        let capsule = RecentPageCapsule(page: page, timestamp: timestamp, action: {})

        let separator = l("list.separator")
        let suras = page.suras.map { $0.localizedName() }
        XCTAssertEqual(suras.count, 3)
        XCTAssertEqual(
            capsule.accessibilityLabel,
            suras[0] + separator + suras[1] + separator + suras[2] + separator + page.localizedName + separator + timestamp
        )
        XCTAssertEqual(capsule.accessibilityLabel.components(separatedBy: separator).last, timestamp)
    }
}
