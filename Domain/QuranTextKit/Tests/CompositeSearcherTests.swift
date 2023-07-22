//
//  CompositeSearcherTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-16.
//

import QuranKit
import QuranText
import SnapshotTesting
import TranslationServiceFake
import VerseTextPersistence
import XCTest
@testable import QuranTextKit

@MainActor
class CompositeSearcherTests: XCTestCase {
    // MARK: Internal

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

    func testSearchArabicSuraName() async throws {
        let result = try await searcher.search(for: "النحل", quran: quran)
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

    // MARK: Private

    private var searcher: CompositeSearcher!
    private var localTranslationsFake: LocalTranslationsFake!
    private let quran = Quran.hafsMadani1405

    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]

    private func autocompleteNumber(_ number: String) async throws {
        let result = try await searcher.autocomplete(term: number, quran: quran)
        XCTAssertEqual(result, [number])
    }

    private func testAutocomplete(term: String, testName: String = #function) async throws {
        let result = try await searcher.autocomplete(term: term, quran: quran)

        // assert the text
        assertSnapshot(matching: result.sorted(), as: .json, testName: testName)
    }
}
