import Localization
import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class NoorExpandableRowHeaderTests: XCTestCase {
    func test_spokenValue_separatesValueAndExpansionStateWithTheListSeparator() {
        let header = makeHeader(isExpanded: true, accessibilityValue: "Al-Baqarah, Ayah 255")

        XCTAssertEqual(header.spokenValue, "Al-Baqarah, Ayah 255; Expanded")
    }

    func test_spokenValue_withoutAccessibilityValue_isExpansionState() {
        let header = makeHeader(isExpanded: false, accessibilityValue: nil)

        XCTAssertEqual(header.spokenValue, l("accessibility.collapsed"))
    }

    private func makeHeader(isExpanded: Bool, accessibilityValue: String?) -> NoorExpandableRowHeader<Text> {
        NoorExpandableRowHeader(
            title: "From",
            isExpanded: isExpanded,
            accessibilityValue: accessibilityValue,
            action: {}
        ) {
            Text("Al-Baqarah · 2:255")
        }
    }
}
