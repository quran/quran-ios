import Foundation
import XCTest
@testable import Localization

final class LocalizationCatalogTests: XCTestCase {
    func testLocalizableStringsMatchEnglishCatalog() throws {
        let english = try strings(for: "en")

        for localization in supportedLocalizations where localization != "en" {
            let localized = try strings(for: localization)
            XCTAssertEqual(
                Set(localized.keys),
                Set(english.keys),
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
        let formatExpression = try! NSRegularExpression(pattern: #"%(?:\d+\$)?([@d])"#)
        let readerExpression = try! NSRegularExpression(pattern: #"%%Readers:[^%]+%%"#)
        let range = NSRange(value.startIndex..., in: value)

        let formatTokens = formatExpression.matches(in: value, range: range).compactMap { match in
            Range(match.range(at: 1), in: value).map { "%\(value[$0])" }
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
