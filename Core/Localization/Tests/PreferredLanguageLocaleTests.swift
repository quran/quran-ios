import Foundation
import XCTest
@testable import Localization

final class PreferredLanguageLocaleTests: XCTestCase {
    func testUsesCurrentLocaleWhenItSpeaksThePreferredLanguage() {
        let current = Locale(identifier: "ar_CA@numbers=arab")

        let locale = Locale.preferredLanguageLocale(preferredLanguages: ["ar"], current: current)

        XCTAssertEqual(locale.identifier, "ar_CA@numbers=arab")
    }

    func testUsesPreferredLanguageWhenCurrentLocaleSpeaksAnotherLanguage() {
        let current = Locale(identifier: "ar_PK")

        let locale = Locale.preferredLanguageLocale(preferredLanguages: ["ur-PK", "ar-PK"], current: current)

        XCTAssertEqual(locale.languageCode, "ur")
    }

    func testUsesCurrentLocaleWithoutPreferredLanguages() {
        let current = Locale(identifier: "en_CA")

        let locale = Locale.preferredLanguageLocale(preferredLanguages: [], current: current)

        XCTAssertEqual(locale.identifier, "en_CA")
    }
}
