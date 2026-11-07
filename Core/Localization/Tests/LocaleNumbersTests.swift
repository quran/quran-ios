import Foundation
import XCTest
@testable import Localization

final class LocaleNumbersTests: XCTestCase {
    // MARK: - Per-app language

    func testPerAppArabicInCanadaUsesArabicIndicDigits() {
        let locale = perApp("ar_CA", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(String(format: "%d", locale: locale, 45), "٤٥")
        XCTAssertEqual(components(of: locale)[NSLocale.Key.countryCode.rawValue], "CA")
    }

    func testPerAppArabicDashIdentifierUsesArabicIndicDigits() {
        let locale = perApp("ar-CA", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testPerAppArabicWithoutRegionUsesArabicIndicDigits() {
        let locale = perApp("ar", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testPerAppArabicIgnoresInheritedLatinNumbers() {
        let locale = perApp("ar_CA@numbers=latn", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testPerAppArabicIgnoresInheritedLatinNumbersAndKeepsRegionOverride() {
        let locale = perApp("ar_US@rg=cazzzz;numbers=latn", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(components(of: locale)["rg"], "cazzzz")
    }

    func testPerAppArabicInUnitedStatesUsesArabicIndicDigits() {
        let locale = perApp("ar_US", system: ["en-US"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testPerAppArabicWithArabicRegionOverrideIsUnchanged() {
        let locale = perApp("ar_US@rg=sazzzz", system: ["en-US"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(locale.identifier, "ar_US@rg=sazzzz")
    }

    func testPerAppArabicWithArabicRegionOverrideIgnoresInheritedLatinNumbers() {
        let locale = perApp("ar_US@rg=sazzzz;numbers=latn", system: ["en-US"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertNil(components(of: locale)["numbers"])
    }

    func testPerAppArabicWithLatinDefaultRegionOverrideUsesArabicIndicDigits() {
        let locale = perApp("ar_SA@rg=uszzzz", system: ["en-US"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(components(of: locale)["rg"], "uszzzz")
    }

    func testPerAppArabicInMoroccoUsesRegionDefaultLatinDigits() {
        let locale = perApp("ar_MA", system: ["fr-MA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testPerAppArabicInEmiratesUsesRegionDefaultLatinDigits() {
        let locale = perApp("ar_AE", system: ["en-AE"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testPerAppArabicInSaudiArabiaIsUnchanged() {
        let locale = perApp("ar_SA", system: ["en-SA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(locale.identifier, "ar_SA")
    }

    func testPerAppArabicInSaudiArabiaIgnoresInheritedLatinNumbers() {
        let locale = perApp("ar_SA@numbers=latn", system: ["en-SA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testPerAppArabicKeepsExplicitNonLatinNumbers() {
        let locale = perApp("ar_CA@numbers=arabext", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "۴۵")
        XCTAssertEqual(locale.identifier, "ar_CA@numbers=arabext")
    }

    func testPerAppArabicKeepsCalendar() {
        let locale = perApp("ar_CA@calendar=islamic", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(locale.calendar.identifier, .islamic)
    }

    func testPerAppPersianDropsInheritedLatinNumbersAndKeepsRegionOverride() {
        let locale = perApp("fa_US@numbers=latn;rg=cazzzz", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "۴۵")
        XCTAssertEqual(components(of: locale)["rg"], "cazzzz")
    }

    func testPerAppPersianKeepsExplicitNonLatinNumbers() {
        let locale = perApp("fa_CA@numbers=arabext", system: ["en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "۴۵")
        XCTAssertEqual(locale.identifier, "fa_CA@numbers=arabext")
    }

    // MARK: - Whole phone

    func testWholePhoneArabicInCanadaUsesArabicIndicDigits() {
        let locale = wholePhone("ar_CA", system: ["ar-CA", "en-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(components(of: locale)[NSLocale.Key.countryCode.rawValue], "CA")
    }

    func testWholePhoneArabicInUnitedStatesUsesArabicIndicDigits() {
        let locale = wholePhone("ar_US", system: ["ar-US"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testWholePhoneArabicWithoutRegionUsesArabicIndicDigits() {
        let locale = wholePhone("ar", system: ["ar"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testWholePhoneArabicInCanadaRespectsExplicitLatinNumbers() {
        let locale = wholePhone("ar_CA@numbers=latn", system: ["ar-CA"])

        XCTAssertEqual(locale.identifier, "ar_CA@numbers=latn")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testWholePhoneArabicRespectsExplicitLatinNumbers() {
        let locale = wholePhone("ar_SA@numbers=latn", system: ["ar-SA"])

        XCTAssertEqual(locale.identifier, "ar_SA@numbers=latn")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testWholePhoneArabicRespectsExplicitArabicNumbers() {
        let locale = wholePhone("ar_CA@numbers=arab", system: ["ar-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testWholePhoneArabicInMoroccoUsesRegionDefaultLatinDigits() {
        let locale = wholePhone("ar_MA", system: ["ar-MA"])

        XCTAssertEqual(locale.identifier, "ar_MA")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testWholePhoneArabicInSaudiArabiaIsUnchanged() {
        let locale = wholePhone("ar_SA", system: ["ar-SA"])

        XCTAssertEqual(locale.identifier, "ar_SA")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testWholePhoneArabicWithArabicRegionOverrideIsUnchanged() {
        let locale = wholePhone("ar_US@rg=sazzzz", system: ["ar-US"])

        XCTAssertEqual(locale.identifier, "ar_US@rg=sazzzz")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testWholePhoneArabicWithLatinDefaultRegionOverrideUsesArabicIndicDigits() {
        let locale = wholePhone("ar_SA@rg=uszzzz", system: ["ar-SA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(components(of: locale)["rg"], "uszzzz")
    }

    func testWholePhoneArabicKeepsCalendar() {
        let locale = wholePhone("ar_CA@calendar=islamic", system: ["ar-CA"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
        XCTAssertEqual(locale.calendar.identifier, .islamic)
    }

    func testWholePhoneFallingBackToArabicRespectsExplicitLatinNumbers() {
        // Urdu isn't an app language, so the app runs in the phone's second language.
        let locale = wholePhone("ar_PK@numbers=latn", system: ["ur-PK", "ar-PK"])

        XCTAssertEqual(locale.identifier, "ar_PK@numbers=latn")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testWholePhoneFallingBackToArabicUsesArabicIndicDigits() {
        let locale = wholePhone("ar_PK", system: ["ur-PK", "ar-PK"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    func testPrimarySystemLanguageMatchingLocaleRespectsExplicitLatinNumbers() {
        let locale = Locale(identifier: "ar_CA@numbers=latn")
            .fixedLocaleNumbers(systemLanguages: ["ar-CA"], appLanguages: ["ar"])

        XCTAssertEqual(locale.identifier, "ar_CA@numbers=latn")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testPrimarySystemLanguageMatchingPersianLocaleRespectsExplicitLatinNumbers() {
        let locale = Locale(identifier: "fa_IR@numbers=latn")
            .fixedLocaleNumbers(systemLanguages: ["fa-IR"], appLanguages: ["fa"])

        XCTAssertEqual(locale.identifier, "fa_IR@numbers=latn")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testWholePhonePersianRespectsExplicitLatinNumbers() {
        let locale = wholePhone("fa@numbers=latn", system: ["fa-IR"])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    func testWholePhoneEnglishInCanadaIsUnchanged() {
        let locale = wholePhone("en_CA", system: ["en-CA"])

        XCTAssertEqual(locale.identifier, "en_CA")
        XCTAssertEqual(numberFormatterString(45, locale: locale), "45")
    }

    // MARK: - Unknown system languages

    func testUnknownSystemLanguagesArabicInCanadaUsesArabicIndicDigits() {
        let locale = Locale(identifier: "ar_CA@numbers=latn").fixedLocaleNumbers(systemLanguages: [], appLanguages: [])

        XCTAssertEqual(numberFormatterString(45, locale: locale), "٤٥")
    }

    // MARK: - Private

    /// The app runs in a per-app language (`ar` or `fa`) on a phone set to `system`.
    private func perApp(_ identifier: String, system: [String]) -> Locale {
        let locale = Locale(identifier: identifier)
        return locale.fixedLocaleNumbers(systemLanguages: system, appLanguages: [locale.languageCode ?? ""])
    }

    /// The app has no per-app language, so it sees the phone's languages.
    private func wholePhone(_ identifier: String, system: [String]) -> Locale {
        Locale(identifier: identifier).fixedLocaleNumbers(systemLanguages: system, appLanguages: system)
    }

    private func numberFormatterString(_ number: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        return formatter.format(number)
    }

    private func components(of locale: Locale) -> [String: String] {
        Locale.components(fromIdentifier: locale.identifier)
    }
}
