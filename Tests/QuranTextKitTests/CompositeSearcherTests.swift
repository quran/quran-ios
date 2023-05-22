//
//  CompositeSearcherTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-16.
//

import QuranKit
@testable import QuranTextKit
import SnapshotTesting
import TestUtilities
import XCTest

class CompositeSearcherTests: XCTestCase {
    private var searcher: CompositeSearcher!
    private var localTranslationsFake: LocalTranslationsFake!
    private let quran = Quran.hafsMadani1405

    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]

    override func setUp() async throws {
        try await super.setUp()

        localTranslationsFake = LocalTranslationsFake()
        let translationsRetriever = localTranslationsFake.retriever
        try await localTranslationsFake.setTranslations(translations)

        let persistence = SQLiteQuranVerseTextPersistence(mode: .arabic, fileURL: TestData.quranTextURL)

        searcher = CompositeSearcher(
            quranVerseTextPersistence: persistence,
            localTranslationRetriever: translationsRetriever,
            versePersistenceBuilder: TestData.translationsPersistenceBuilder
        )
    }

    override func tearDown() {
        super.tearDown()
        localTranslationsFake.tearDown()
    }

    func testAutocompleteNumbers() throws {
        try autocompleteNumber("4")
        try autocompleteNumber("44")
        try autocompleteNumber("444")
        try autocompleteNumber("4444")
        try autocompleteNumber("3:4")
    }

    private func autocompleteNumber(_ number: String) throws {
        let result = try wait(for: searcher.autocomplete(term: number, quran: quran))
        XCTAssertEqual(result, [SearchAutocompletion(text: number, term: number)])
    }

    func testSearchNumber1() throws {
        let result = try wait(for: searcher.search(for: "1", quran: quran))
        assertSnapshot(matching: result, as: .json)
    }

    func testSearchNumber33() throws {
        let result = try wait(for: searcher.search(for: "33", quran: quran))
        assertSnapshot(matching: result, as: .json)
    }

    func testSearchNumber605() throws {
        let result = try wait(for: searcher.search(for: "605", quran: quran))
        XCTAssertEqual(result, [])
    }

    func testSearchNumberVerse() throws {
        let result = try wait(for: searcher.search(for: "68:1", quran: quran))
        assertSnapshot(matching: result, as: .json)
    }

    func testAutocompleteSura() throws {
        try testAutocomplete(term: "Yu")
    }

    func testSearchOneSura() throws {
        let result = try wait(for: searcher.search(for: "Al-Ahzab", quran: quran))
        assertSnapshot(matching: result, as: .json)
    }

    func testSearchMultipleSura() throws {
        let result = try wait(for: searcher.search(for: "Yu", quran: quran))
        assertSnapshot(matching: result, as: .json)
    }

    func testAutocompleteArabicQuran() throws {
        let term = "لكنا"
        try testAutocomplete(term: term)
    }

    func testSearchArabicQuran() throws {
        let term = "لكنا"
        let result = try wait(for: searcher.search(for: term, quran: quran))
        assertSnapshot(matching: result, as: .json)
    }

    func testAutocompleteTranslation() throws {
        try testAutocomplete(term: "All")
    }

    func testSearchTranslation() throws {
        let result = try wait(for: searcher.search(for: "All", quran: quran))
        assertSnapshot(matching: result, as: .json)
    }

    private func testAutocomplete(term: String, testName: String = #function) throws {
        let result = try wait(for: searcher.autocomplete(term: term, quran: quran))

        // assert the range
        let ranges = Set(result.map(\.highlightedRange))
        XCTAssertEqual(ranges, [NSRange(location: 0, length: (term as NSString).length)])

        // assert the text
        assertSnapshot(matching: result.map(\.text).sorted(), as: .json, testName: testName)
    }
}
