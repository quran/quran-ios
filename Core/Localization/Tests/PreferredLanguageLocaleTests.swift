import Foundation
import XCTest
@testable import Localization

final class PreferredLanguageLocaleTests: XCTestCase {
    func testUsesCurrentLocaleWhenItSpeaksTheResolvedLanguage() {
        let current = Locale(identifier: "ar_PK")

        let locale = Locale.preferredLanguageLocale(localization: "ar", preferredLanguages: ["ur-PK", "ar-PK"], current: current)

        XCTAssertEqual(locale.identifier, "ar_PK")
    }

    func testUsesPreferredLanguageRegionWhenCurrentLocaleSpeaksAnotherLanguage() {
        let current = Locale(identifier: "en_CA")

        let locale = Locale.preferredLanguageLocale(localization: "ar", preferredLanguages: ["ar-SA", "en-CA"], current: current)

        XCTAssertEqual(locale.languageCode, "ar")
        XCTAssertEqual(locale.regionCode, "SA")
        let formatter = NumberFormatter()
        formatter.locale = locale.fixedLocaleNumbers()
        XCTAssertEqual(formatter.format(45), "٤٥")
    }

    func testUsesFirstPreferredLanguageInTheResolvedLanguage() {
        let current = Locale(identifier: "en_CA")

        let locale = Locale.preferredLanguageLocale(localization: "ar", preferredLanguages: ["ur-PK", "ar-PK"], current: current)

        XCTAssertEqual(locale.languageCode, "ar")
        XCTAssertEqual(locale.regionCode, "PK")
    }

    func testUsesCurrentLocaleWithoutResolvedLanguage() {
        let current = Locale(identifier: "en_CA")

        let locale = Locale.preferredLanguageLocale(localization: nil, preferredLanguages: ["en-CA"], current: current)

        XCTAssertEqual(locale.identifier, "en_CA")
    }

    func testNamesTheLocalizationThatStringsResolveTo() throws {
        let key = "menu.translation"
        let languageCode = try XCTUnwrap(Locale.preferredLanguageLocale.languageCode)
        let path = try XCTUnwrap(Bundle.fixedModule.path(forResource: languageCode, ofType: "lproj"))
        let bundle = try XCTUnwrap(Bundle(path: path))

        XCTAssertEqual(bundle.localizedString(forKey: key, value: nil, table: "Localizable"), l(key))
    }
}
