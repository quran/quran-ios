//
//  CompositeSearcherTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-16.
//

import Localization
import QuranKit
import QuranText
import SnapshotTesting
import TranslationServiceFake
import VerseTextPersistence
import XCTest
@testable import QuranTextKit

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

    func testNumbers() async throws {
        await autocompleteNumber("4")
        await autocompleteNumber("44")
        await autocompleteNumber("444")
        await autocompleteNumber("4444")
        await autocompleteNumber("3:4")

        try await testSearch(term: "1")
        try await testSearch(term: "33")
        try await testSearch(term: "68:1") // Verse
    }

    func testSearchInvalidNumber() async throws {
        let result = try await searcher.search(for: "605", quran: quran)
        XCTAssertEqual(result, [])
    }

    func testMatchOneSura() async throws {
        await testAutocomplete(term: "Al-Ahzab")
        try await testSearch(term: "Al-Ahzab")
    }

    func testMatchMultipleSuras() async throws {
        await testAutocomplete(term: "Yu")
        try await testSearch(term: "Yu")
    }

    func testMatchSuraAndQuran() async throws {
        await testAutocomplete(term: "الفات") // Al-fatiha
        await testAutocomplete(term: "الاحۡ") // Al-Ahzab
        await testAutocomplete(term: "الأَعۡلَ") // Al-A'la

        try await testSearch(term: "الفات") // Al-fatiha
        try await testSearch(term: "الاحۡ") // Al-Ahzab
        try await testSearch(term: "الأَعۡلَ") // Al-A'la
    }

    func testMatchArabicSuraName() async throws {
        await testAutocomplete(term: "النحل")
        try await testSearch(term: "النحل")
    }

    func testMatchSuraAndQuranWithIncorrectTashkeel() async throws {
        await testAutocomplete(term: "فُتح")
        try await testSearch(term: "فُتح")
    }

    func testMatchArabicQuran() async throws {
        let term = "لكنا"
        await testAutocomplete(term: term)
        try await testSearch(term: term)
    }

    func testMatchTranslation() async throws {
        await testAutocomplete(term: "All")
        try await testSearch(term: "All")
    }

    func test_autocomplete_allSuras_prefixed() async {
        await enumerateAllSuras { sura, language in
            // Autocomplete sura name unchanged.
            let suraName = sura.localizedName(withPrefix: false, language: language)
            let suraNamePrefix = prefixSuraName(suraName)
            let result = await searcher.autocomplete(term: suraNamePrefix, quran: quran)
                .map { $0.removeInvalidSearchCharacters() }
            let strippedSuraName = suraName.removeInvalidSearchCharacters()
            XCTAssertTrue(result.contains(strippedSuraName), "[\(language)] \(result) doesn't contain \(strippedSuraName)")
        }
    }

    func test_match_allSuras_removeInvalidSearchCharacters() async throws {
        try await enumerateAllSuras { sura, language in
            let suraName = sura.localizedName(withPrefix: false, language: language)
            let fullSuraName = sura.localizedName(withPrefix: true, language: language)
            let cleanedSuraName = suraName.removeInvalidSearchCharacters()
            let cleanedSuraNamePrefix = prefixSuraName(cleanedSuraName)

            // Check autocomplete partial pure letters and spaces sura name results contains the full sura name.
            let autocompleteResult = await searcher.autocomplete(term: cleanedSuraNamePrefix, quran: quran)
                .map { $0.removeInvalidSearchCharacters() }
            XCTAssertTrue(autocompleteResult.contains(cleanedSuraName), "[\(language)] \(autocompleteResult) doesn't contain \(cleanedSuraName)")

            // Check search partial pure letters and spaces sura name results contains the full sura name.
            let searchResult = try await searcher.search(for: cleanedSuraNamePrefix, quran: quran)
                .flatMap { $0.items.map(\.text) }
            XCTAssertTrue(searchResult.contains(fullSuraName), "[\(language)] \(searchResult) doesn't contain \(fullSuraName)")
        }
    }

    // MARK: Private

    private var searcher: CompositeSearcher!
    private var localTranslationsFake: LocalTranslationsFake!
    private let quran = Quran.hafsMadani1405

    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]

    private func autocompleteNumber(_ number: String) async {
        let result = await searcher.autocomplete(term: number, quran: quran)
        XCTAssertEqual(result, [number])
    }

    @MainActor
    private func testAutocomplete(term: String, record: Bool = false, testName: String = #function) async {
        let result = await searcher.autocomplete(term: term, quran: quran)

        // assert the text
        assertSnapshot(of: result.sorted(), as: .json, record: record, testName: testName)
    }

    @MainActor
    private func testSearch(term: String, record: Bool = false, testName: String = #function) async throws {
        let result = try await searcher.search(for: term, quran: quran)

        // assert the text
        assertSnapshot(of: EncodableSearchResults(results: result), as: .json, record: record, testName: testName)
    }

    private func enumerateAllSuras(_ block: (Sura, Language) async throws -> Void) async rethrows {
        for language in [Language.arabic, Language.english] {
            for sura in quran.suras {
                try await block(sura, language)
            }
        }
    }

    private func prefixSuraName(_ suraName: String) -> String {
        suraName.count == 1 ? suraName : String(suraName.prefix(suraName.count - 1))
    }
}
