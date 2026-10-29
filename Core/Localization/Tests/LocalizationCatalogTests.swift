import Foundation
import XCTest
@testable import Localization

final class LocalizationCatalogTests: XCTestCase {
    func testLocalizableStringsMatchEnglishCatalog() throws {
        let english = try strings(for: "en")

        for localization in supportedLocalizations where localization != "en" {
            let localized = try strings(for: localization)
            let englishKeys = Set(english.keys)
            let fallbackKeys = localization == "ar"
                ? englishOnlyFallbackKeys
                : englishFallbackKeys
            let expectedKeys = englishKeys.subtracting(fallbackKeys)
            XCTAssertEqual(
                Set(localized.keys),
                expectedKeys,
                "\(localization) Localizable.strings keys differ from English."
            )

            for key in english.keys where localized[key] != nil {
                XCTAssertEqual(
                    formatTokens(in: localized[key, default: ""]),
                    formatTokens(in: english[key, default: ""]),
                    "\(localization) has incompatible format placeholders for \(key)."
                )
            }
        }
    }

    func testLocalizableStringsdictMatchEnglishCatalog() throws {
        let english = try stringsdict(for: "en")

        for localization in supportedLocalizations where localization != "en" {
            XCTAssertEqual(
                Set(try stringsdict(for: localization).keys),
                Set(english.keys),
                "\(localization) Localizable.stringsdict keys differ from English."
            )
        }
    }

    func testRequiredAndroidStringsExistInEveryLocalization() throws {
        let requiredAndroidKeys = try requiredAndroidKeys()
        for localization in supportedLocalizations {
            let availableKeys = Set(try strings(named: "Android", for: localization).keys)
                .union(try stringsdict(named: "Android", for: localization).keys)
            let missingKeys = requiredAndroidKeys.subtracting(availableKeys)
            XCTAssertTrue(
                missingKeys.isEmpty,
                "\(localization) is missing used Android strings: \(missingKeys.sorted())."
            )
        }
    }

    func testReferenceFormatsUseEachLocalizationsComma() throws {
        let commas = [
            "ar": "، ",
            "fa": "، ",
            "ug": "، ",
            "zh": "，",
        ]

        for localization in supportedLocalizations {
            let localized = try strings(for: localization)
            let comma = commas[localization, default: ", "]
            XCTAssertEqual(localized["list.separator.comma"], comma, "\(localization) list.separator.comma")
            // Translators may reorder the placeholders, so only check the comma is there.
            let referenceComma = comma.trimmingCharacters(in: .whitespaces)
            for key in ["quran.ayah.name", "quran.page.location"] {
                XCTAssertTrue(
                    localized[key, default: ""].contains(referenceComma),
                    "\(localization) \(key) is missing \(referenceComma)"
                )
            }
        }
    }

    func testAyahNumberFollowsAndroidExceptChineseWordOrder() throws {
        for localization in supportedLocalizations {
            let ayahNumber = try strings(for: localization)["quran.ayah.number", default: ""]
            let android = try strings(named: "Android", for: localization)["quran_ayah", default: ""]
            if localization == "zh" {
                XCTAssertEqual(ayahNumber, "第%1$d节")
            } else {
                XCTAssertEqual(ayahNumber, android, "\(localization) quran.ayah.number differs from Android's quran_ayah")
            }
        }
    }

    func testReciterLanguageTitlesWrapTheLanguageInEachLocalizationsParentheses() throws {
        for localization in supportedLocalizations {
            let localized = try strings(for: localization)
            let parenthesized = localization == "zh" ? "（%@）" : "(%@)"
            XCTAssertTrue(
                localized["reciters.all-language", default: ""].contains(parenthesized),
                "\(localization) reciters.all-language is missing \(parenthesized)"
            )
        }
    }

    func testAudioDownloadSubtitleUsesTheMetadataSeparator() throws {
        for localization in supportedLocalizations {
            let localized = try strings(for: localization)
            // Translators may reorder the placeholders, so only check the separator is there.
            XCTAssertTrue(
                localized["audio.downloads.size-and-files", default: ""].contains(" · "),
                "\(localization) audio.downloads.size-and-files is missing \" · \""
            )
        }
    }

    func testChineseUsesFullWidthColonsAndParentheses() throws {
        // A colon between two numbers, such as an ayah coordinate "%d:%d", stays half-width.
        let numericColon = try NSRegularExpression(pattern: #"(\d|%(\d+\$)?[@d]):(?=\d|%)"#)
        for (key, value) in try strings(for: "zh") {
            let range = NSRange(value.startIndex..., in: value)
            let text = numericColon.stringByReplacingMatches(in: value, range: range, withTemplate: "$1")
            XCTAssertNil(
                text.rangeOfCharacter(from: CharacterSet(charactersIn: ":()")),
                "zh \(key) uses half-width punctuation: \(value)"
            )
        }
    }

    // MARK: - Private

    private let supportedLocalizations = [
        "ar",
        "de",
        "en",
        "es",
        "fa",
        "fr",
        "kk",
        "ms",
        "nl",
        "pt",
        "ru",
        "tr",
        "ug",
        "uz",
        "vi",
        "zh",
    ]

    private let englishFallbackKeys: Set<String> = [
        "quran.sura-name.indopak.17",
        "quran.sura-name.indopak.40",
        "quran.sura-name.indopak.41",
        "quran.sura-name.indopak.76",
        "quran.sura-name.indopak.111",
        "quran.sura-name-translation.indopak.17",
        "quran.sura-name-translation.indopak.40",
        "quran.sura-name-translation.indopak.41",
        "quran.sura-name-translation.indopak.76",
        "quran.sura-name-translation.indopak.111",
    ]

    private let englishOnlyFallbackKeys: Set<String> = [
        "quran.sura-name-translation.indopak.17",
        "quran.sura-name-translation.indopak.40",
        "quran.sura-name-translation.indopak.41",
        "quran.sura-name-translation.indopak.76",
        "quran.sura-name-translation.indopak.111",
    ]

    private func strings(for localization: String) throws -> [String: String] {
        try strings(named: "Localizable", for: localization)
    }

    private func stringsdict(for localization: String) throws -> [String: Any] {
        try stringsdict(named: "Localizable", for: localization)
    }

    private func strings(named table: String, for localization: String) throws -> [String: String] {
        try propertyList(named: "\(table).strings", for: localization)
    }

    private func stringsdict(named table: String, for localization: String) throws -> [String: Any] {
        try propertyList(named: "\(table).stringsdict", for: localization)
    }

    private func propertyList<Value>(
        named name: String,
        for localization: String
    ) throws -> [String: Value] {
        let bundleURL = try XCTUnwrap(
            Bundle.fixedModule.url(forResource: localization, withExtension: "lproj"),
            "Missing \(localization).lproj."
        )
        let bundle = try XCTUnwrap(Bundle(url: bundleURL))
        let components = name.split(separator: ".", maxSplits: 1).map(String.init)
        let resourceURL = try XCTUnwrap(
            bundle.url(forResource: components[0], withExtension: components[1]),
            "Missing \(name) for \(localization)."
        )
        let data = try Data(contentsOf: resourceURL)
        let propertyList = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(propertyList as? [String: Value])
    }

    private func requiredAndroidKeys() throws -> Set<String> {
        let configurationURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Generator/AndroidImport.json")
        let data = try Data(contentsOf: configurationURL)
        return try JSONDecoder()
            .decode(AndroidImportConfiguration.self, from: data)
            .requiredKeys
    }

    private func formatTokens(in value: String) -> [String] {
        let formatExpression = try! NSRegularExpression(pattern: #"%(?:(\d+)\$)?([@d])"#)
        let readerExpression = try! NSRegularExpression(pattern: #"%%Readers:[^%]+%%"#)
        let range = NSRange(value.startIndex..., in: value)

        // Number bare placeholders in order, so "%@ - %@" matches "%2$@ - %1$@",
        // but a dropped or repeated positional placeholder doesn't.
        var bareIndex = 0
        let formatTokens = formatExpression.matches(in: value, range: range).compactMap { match -> String? in
            guard let typeRange = Range(match.range(at: 2), in: value) else {
                return nil
            }
            let index: String
            if let indexRange = Range(match.range(at: 1), in: value) {
                index = String(value[indexRange])
            } else {
                bareIndex += 1
                index = String(bareIndex)
            }
            return "%\(index)$\(value[typeRange])"
        }
        let readerTokens = readerExpression.matches(in: value, range: range).compactMap { match in
            Range(match.range, in: value).map { String(value[$0]) }
        }
        return (formatTokens + readerTokens).sorted()
    }
}

private struct AndroidImportConfiguration: Decodable {
    let requiredKeys: Set<String>
}
