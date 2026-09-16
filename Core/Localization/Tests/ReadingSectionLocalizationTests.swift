import Foundation
import XCTest
@testable import Localization

final class ReadingSectionLocalizationTests: XCTestCase {
    func testAdditionalBookmarksUseEnglishSingularAndPlural() throws {
        XCTAssertEqual(try moreBookmarks(1, language: "en"), "1 more bookmark")
        XCTAssertEqual(try moreBookmarks(2, language: "en"), "2 more bookmarks")
    }

    func testAdditionalBookmarksUseArabicPluralForms() throws {
        XCTAssertEqual(try moreBookmarks(0, language: "ar"), "لا توجد علامات إضافية")
        XCTAssertEqual(try moreBookmarks(1, language: "ar"), "علامة إضافية واحدة")
        XCTAssertEqual(try moreBookmarks(2, language: "ar"), "علامتان إضافيتان")
        XCTAssertTrue(try moreBookmarks(3, language: "ar").contains("علامات إضافية"))
        XCTAssertTrue(try moreBookmarks(11, language: "ar").contains("علامة إضافية"))
    }

    func testAdditionalBookmarksUseRussianPluralForms() throws {
        XCTAssertEqual(try moreBookmarks(1, language: "ru"), "Ещё 1 закладка")
        XCTAssertEqual(try moreBookmarks(2, language: "ru"), "Ещё 2 закладки")
        XCTAssertEqual(try moreBookmarks(5, language: "ru"), "Ещё 5 закладок")
        XCTAssertEqual(try moreBookmarks(21, language: "ru"), "Ещё 21 закладка")
    }

    func testEveryReadingSectionTranslationResolves() throws {
        let keys = [
            "home.continue-reading.title",
            "bookmarks.reading.title",
            "bookmarks.reading.show-less",
            "accessibility.expanded",
            "accessibility.collapsed",
        ]
        for language in Bundle.fixedModule.localizations where language != "Base" {
            let bundle = try bundle(language: language)
            for key in keys {
                let text = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
                XCTAssertNotEqual(text, key, "Missing \(language): \(key)")
                XCTAssertFalse(text.isEmpty)
            }
            let format = bundle.localizedString(forKey: "home.recent-pages.title", value: nil, table: "Localizable")
            let recentPages = String(format: format, "3")
            XCTAssertTrue(recentPages.contains("3"), language)
            for count in [0, 1, 2, 3, 5, 11, 21, 100] {
                let text = try moreBookmarks(count, language: language)
                XCTAssertFalse(text.contains("%"), "Unresolved plural in \(language): \(text)")
                XCTAssertFalse(text.contains("bookmarks.reading.more-count"), language)
            }
        }
    }

    private func moreBookmarks(_ count: Int, language: String) throws -> String {
        let format = try bundle(language: language)
            .localizedString(forKey: "bookmarks.reading.more-count", value: nil, table: "Localizable")
        return String(format: format, locale: Locale(identifier: language), arguments: [count])
    }

    private func bundle(language: String) throws -> Bundle {
        let url = try XCTUnwrap(Bundle.fixedModule.url(forResource: language, withExtension: "lproj"))
        return try XCTUnwrap(Bundle(url: url))
    }
}
