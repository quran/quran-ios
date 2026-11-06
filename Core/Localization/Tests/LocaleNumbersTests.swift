import Foundation
import Localization
import XCTest

final class LocaleNumbersTests: XCTestCase {
    func testArabicInLatinDefaultRegionUsesArabicIndicDigits() {
        let locale = Locale(identifier: "ar_CA").fixedLocaleNumbers()

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(String(format: "%d", locale: locale, 45), "٤٥")
        XCTAssertEqual(components(of: locale)[NSLocale.Key.countryCode.rawValue], "CA")
    }

    func testArabicWithExplicitLatinNumbersUsesArabicIndicDigits() {
        let locale = Locale(identifier: "ar_CA@numbers=latn").fixedLocaleNumbers()

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(String(format: "%d", locale: locale, 45), "٤٥")
    }

    func testArabicWithRegionOverrideAndLatinNumbersKeepsRegionOverride() {
        let locale = Locale(identifier: "ar_US@rg=cazzzz;numbers=latn").fixedLocaleNumbers()

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(components(of: locale)[NSLocale.Key.countryCode.rawValue], "US")
        XCTAssertEqual(components(of: locale)["rg"], "cazzzz")
    }

    func testArabicInArabicDefaultRegionIsUnchanged() {
        let locale = Locale(identifier: "ar_SA").fixedLocaleNumbers()

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        if #available(iOS 16, *) {
            XCTAssertEqual(locale.identifier, "ar_SA")
        }
    }

    func testArabicKeepsExplicitNonLatinNumbers() {
        let locale = Locale(identifier: "ar_CA@numbers=arabext").fixedLocaleNumbers()

        XCTAssertEqual(numberFormatterString(45, locale: locale), "۴۵")
        XCTAssertEqual(locale.identifier, "ar_CA@numbers=arabext")
    }

    func testArabicKeepsCalendar() {
        let locale = Locale(identifier: "ar_CA@calendar=islamic").fixedLocaleNumbers()

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(locale.calendar.identifier, .islamic)
    }

    func testEnglishInCanadaIsUnchanged() {
        let locale = Locale(identifier: "en_CA").fixedLocaleNumbers()

        XCTAssertEqual(locale.identifier, "en_CA")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
        XCTAssertEqual(String(format: "%d", locale: locale, 45), "45")
    }

    func testNonArabicDropsExplicitLatinNumbers() {
        let locale = Locale(identifier: "en@numbers=latn").fixedLocaleNumbers()

        XCTAssertNil(components(of: locale)["numbers"])
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testPersianIsUnchanged() {
        let locale = Locale(identifier: "fa").fixedLocaleNumbers()

        XCTAssertEqual(locale.identifier, "fa")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "۴۵")
    }

    func testPersianWithLatinNumbersBeforeOtherKeywordsUsesPersianDigits() {
        let locale = Locale(identifier: "fa_CA@numbers=latn;rg=cazzzz").fixedLocaleNumbers()

        XCTAssertEqual(numberFormatterString(45, locale: locale), "۴۵")
        XCTAssertEqual(components(of: locale)["rg"], "cazzzz")
    }

    // MARK: - Private

    private func numberFormatterString(_ number: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        return formatter.format(number)
    }

    private func components(of locale: Locale) -> [String: String] {
        Locale.components(fromIdentifier: locale.identifier)
    }
}
