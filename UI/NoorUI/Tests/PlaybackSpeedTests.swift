import Localization
import XCTest
@testable import NoorUI

final class PlaybackSpeedTests: XCTestCase {
    func testSupportedRatesIncludeFineStepsAroundNormalSpeed() {
        XCTAssertEqual(PlaybackSpeed.supportedRates, [0.25, 0.5, 0.75, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0])
    }

    func testSupportedRatesAreStrictlyAscending() {
        let rates = PlaybackSpeed.supportedRates
        XCTAssertTrue(zip(rates, rates.dropFirst()).allSatisfy { $0 < $1 })
    }

    func testFineRatesFormatWithOneFractionDigit() {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current.fixedLocaleNumbers()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        // Float(0.9) and Float(1.1) are not exact; the label must not leak the binary error.
        XCTAssertEqual(PlaybackSpeed.formatted(0.9), formatter.format(0.9 as Double) + "×")
        XCTAssertEqual(PlaybackSpeed.formatted(1.1), formatter.format(1.1 as Double) + "×")
    }
}
