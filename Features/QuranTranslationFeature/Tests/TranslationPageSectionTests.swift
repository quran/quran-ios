//
//  TranslationPageSectionTests.swift
//

import AnnotationsService
import QuranKit
import QuranText
import QuranTextKit
import XCTest
@testable import QuranTranslationFeature

@MainActor
final class TranslationPageSectionTests: XCTestCase {
    func testScrollTargetReturnsItemOnThisPage() {
        let page = Quran.hafsMadani1405.pages[1]
        let section = makeSection(page: page)

        XCTAssertEqual(section.scrollTarget(for: .pageHeader(page)), .pageHeader(page))
        XCTAssertEqual(section.scrollTarget(for: .pageFooter(page)), .pageFooter(page))
    }

    func testScrollTargetIgnoresItemsOutsideThisPage() {
        let page = Quran.hafsMadani1405.pages[1]
        let otherPage = Quran.hafsMadani1405.pages[2]
        let section = makeSection(page: page)

        XCTAssertNil(section.scrollTarget(for: .pageHeader(otherPage)))
        XCTAssertNil(section.scrollTarget(for: .pageFooter(otherPage)))
        XCTAssertNil(section.scrollTarget(for: .arabic(otherPage.firstVerse)))
    }

    func testScrollTargetIsNilForEmptySection() {
        let page = Quran.hafsMadani1405.pages[1]
        let section = TranslationPageSection(page: page, items: [])

        XCTAssertNil(section.scrollTarget(for: .pageHeader(page)))
    }

    func testSectionIdIsItsPage() {
        let page = Quran.hafsMadani1405.pages[3]

        XCTAssertEqual(makeSection(page: page).id, page)
    }

    func testPageSectionWrapsLoadedPageItems() throws {
        let verse = Quran.hafsMadani1405.pages[1].firstVerse
        let sut = makeLoadedSUT(verse: verse)

        let section = try XCTUnwrap(sut.pageSection(quranFont: .uthmanicHafs))

        XCTAssertEqual(section.page, verse.page)
        XCTAssertEqual(section.id, verse.page)
        XCTAssertEqual(section.items, sut.items(quranFont: .uthmanicHafs))
        XCTAssertEqual(section.items.first?.id, .pageHeader(verse.page))
        XCTAssertEqual(section.items.last?.id, .pageFooter(verse.page))
    }

    func testPageSectionScrollTargetCoversLoadedVerse() throws {
        let verse = Quran.hafsMadani1405.pages[1].firstVerse
        let otherVerse = Quran.hafsMadani1405.pages[2].firstVerse
        let sut = makeLoadedSUT(verse: verse)

        let section = try XCTUnwrap(sut.pageSection(quranFont: .uthmanicHafs))

        XCTAssertEqual(section.scrollTarget(for: .arabic(verse)), .arabic(verse))
        XCTAssertNil(section.scrollTarget(for: .arabic(otherVerse)))
    }

    func testPageSectionIsNilBeforeContentLoads() {
        let sut = makeSUT()

        XCTAssertNil(sut.pageSection(quranFont: .uthmanicHafs))
    }

    func testPageSectionIsNilWhenLoadedTranslationsMismatchSelection() {
        let verse = Quran.hafsMadani1405.pages[1].firstVerse
        let sut = makeSUT()
        sut.verses = [verse]
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )

        XCTAssertNil(sut.pageSection(quranFont: .uthmanicHafs))
    }

    func testPageSectionWithoutHeaderAndFooterKeepsVerseRows() throws {
        let verse = Quran.hafsMadani1405.pages[1].firstVerse
        let sut = makeLoadedSUT(verse: verse)
        sut.showHeaderAndFooter = false

        let section = try XCTUnwrap(sut.pageSection(quranFont: .uthmanicHafs))

        XCTAssertEqual(section.page, verse.page)
        XCTAssertFalse(section.items.isEmpty)
        XCTAssertFalse(section.items.contains { $0.id == .pageHeader(verse.page) })
        XCTAssertFalse(section.items.contains { $0.id == .pageFooter(verse.page) })
        XCTAssertNotEqual(section.items.first?.id, .pageHeader(verse.page))
        XCTAssertEqual(section.scrollTarget(for: .arabic(verse)), .arabic(verse))
        XCTAssertNil(section.scrollTarget(for: .pageHeader(verse.page)))
    }

    func testPageSectionsOfDifferentPagesHaveDifferentIds() throws {
        let firstSUT = makeLoadedSUT(verse: Quran.hafsMadani1405.pages[0].firstVerse)
        let secondSUT = makeLoadedSUT(verse: Quran.hafsMadani1405.pages[1].firstVerse)

        let first = try XCTUnwrap(firstSUT.pageSection(quranFont: .uthmanicHafs))
        let second = try XCTUnwrap(secondSUT.pageSection(quranFont: .uthmanicHafs))

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertNotEqual(first, second)
    }

    override func setUp() {
        super.setUp()
        QuranContentStatePreferences.shared.showArabicInTranslation = true
    }

    override func tearDown() {
        QuranContentStatePreferences.shared.showArabicInTranslation = true
        super.tearDown()
    }

    private func makeSection(page: Page) -> TranslationPageSection {
        TranslationPageSection(
            page: page,
            items: [
                .pageHeader(TranslationPageHeader(page: page)),
                .pageFooter(TranslationPageFooter(page: page)),
            ]
        )
    }

    private func makeLoadedSUT(verse: AyahNumber) -> ContentTranslationViewModel {
        let sut = makeSUT()
        sut.verses = [verse]
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )
        return sut
    }

    private func makeSUT() -> ContentTranslationViewModel {
        let unavailableURL = URL(fileURLWithPath: "/tmp/unavailable-quran-translation-test")
        return ContentTranslationViewModel(
            localTranslationsRetriever: .init(databasesURL: unavailableURL),
            dataService: .init(databasesURL: unavailableURL, quranFileURL: unavailableURL),
            overlayService: VerseOverlayService()
        )
    }

    private func makeTranslation(id: Translation.ID) -> Translation {
        Translation(
            id: id,
            displayName: "Translation \(id)",
            translator: nil,
            translatorForeign: nil,
            fileURL: URL(string: "https://example.com/translation-\(id).zip")!,
            fileName: "translation-\(id).db",
            languageCode: "en",
            version: 1
        )
    }

    private func makeVerseText(translationCount: Int) -> VerseText {
        VerseText(
            arabicText: "Arabic",
            translations: (0 ..< translationCount).map { index in
                .string(.init(
                    text: "Translation \(index)",
                    quranRanges: [],
                    footnoteRanges: [],
                    footnotes: []
                ))
            },
            arabicPrefix: [],
            arabicSuffix: []
        )
    }
}
