import XCTest
@testable import NoorUI

final class DimmedAyahOpacityTests: XCTestCase {
    func testDarkPagesDimLess() {
        XCTAssertGreaterThan(
            DimmedAyahOpacity.value(isDark: true, increasesContrast: false),
            DimmedAyahOpacity.value(isDark: false, increasesContrast: false)
        )
    }

    func testIncreaseContrastDimsLess() {
        XCTAssertGreaterThan(
            DimmedAyahOpacity.value(isDark: false, increasesContrast: true),
            DimmedAyahOpacity.value(isDark: false, increasesContrast: false)
        )
    }
}
