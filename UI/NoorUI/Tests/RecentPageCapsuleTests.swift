import QuranKit
import XCTest
@testable import NoorUI

@MainActor
final class RecentPageCapsuleTests: XCTestCase {
    func test_accessibilityLabel_separatesSuraNamesPageAndDateWithTheListSeparator() {
        let page = Quran.hafsMadani1405.pages.last!
        let timestamp = "Monday, October 14, 2026"
        let capsule = RecentPageCapsule(page: page, timestamp: timestamp, action: {})

        XCTAssertEqual(page.suras.count, 3)
        XCTAssertEqual(capsule.accessibilityLabel, "Al-Ikhlāṣ, Al-Falaq, An-Nās; Page 604; Monday, October 14, 2026")
    }
}
