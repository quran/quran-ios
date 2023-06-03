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

        let persistence = GRDBQuranVerseTextPersistence(mode: .arabic, fileURL: TestData.quranTextURL)

        searcher = CompositeSearcher(
            quranVerseTextPersistence: persistence,
            localTranslationRetriever: translationsRetriever,
            versePersistenceBuilder: TestData.translationsPersistenceBuilder
        )
    }

    override func tearDown() {
        super.tearDown()
        localTranslationsFake.tearDown()
        localTranslationsFake = nil
        searcher = nil
    }

    func testAutocompleteNumbers() async throws {
        try await autocompleteNumber("4")
        try await autocompleteNumber("44")
        try await autocompleteNumber("444")
        try await autocompleteNumber("4444")
        try await autocompleteNumber("3:4")
    }

    private func autocompleteNumber(_ number: String) async throws {
        let result = try await searcher.autocomplete(term: number, quran: quran)
        XCTAssertEqual(result, [SearchAutocompletion(text: number, term: number)])
    }

    func testSearchNumber1() async throws {
        let result = try await searcher.search(for: "1", quran: quran)
        assertSnapshot(matching: result, as: .json)
    }

    func testSearchNumber33() async throws {
        let result = try await searcher.search(for: "33", quran: quran)
        assertSnapshot(matching: result, as: .json)
    }

    func testSearchNumber605() async throws {
        let result = try await searcher.search(for: "605", quran: quran)
        XCTAssertEqual(result, [])
    }

    func testSearchNumberVerse() async throws {
        let result = try await searcher.search(for: "68:1", quran: quran)
        assertSnapshot(matching: result, as: .json)
    }

    func testAutocompleteSura() async throws {
        try await testAutocomplete(term: "Yu")
    }

    func testSearchOneSura() async throws {
        let result = try await searcher.search(for: "Al-Ahzab", quran: quran)
        assertSnapshot(matching: result, as: .json)
    }

    func testSearchMultipleSura() async throws {
        let result = try await searcher.search(for: "Yu", quran: quran)
        assertSnapshot(matching: result, as: .json)
    }

    func testAutocompleteArabicQuran() async throws {
        let term = "لكنا"
        try await testAutocomplete(term: term)
    }

    func testSearchArabicQuran() async throws {
        let term = "لكنا"
        let result = try await searcher.search(for: term, quran: quran)
        assertSnapshot(matching: result, as: .json)
    }

    func testAutocompleteTranslation() async throws {
        try await testAutocomplete(term: "All")
    }

    func testSearchTranslation() async throws {
        let result = try await searcher.search(for: "All", quran: quran)
        assertSnapshot(matching: result, as: .json)
    }

    private func testAutocomplete(term: String, testName: String = #function) async throws {
        let result = try await searcher.autocomplete(term: term, quran: quran)

        // assert the range
        let ranges = Set(result.map(\.highlightedRange))
        XCTAssertEqual(ranges, [NSRange(location: 0, length: (term as NSString).length)])

        // assert the text
        assertSnapshot(matching: result.map(\.text).sorted(), as: .json, testName: testName)
    }
}
