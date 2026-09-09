//
//  SearchTermTests.swift
//
//
//  Created by Abdullah Levin on 2026-09-07.
//

import QuranKit
import XCTest
@testable import QuranTextKit

final class SearchTermTests: XCTestCase {
    // MARK: Internal

    func testKehehMatchesArabicKaf() {
        XCTAssertTrue(matches("کتاب", in: "ذلك الكتاب لا ريب فيه"))
    }

    func testYehVariantsMatchArabicYeh() {
        for yeh in ["ی", "ے", "ې", "ۍ", "ۓ"] {
            XCTAssertTrue(matches("الذ" + yeh, in: "الذي خلق"), "\(yeh) doesn't match Arabic yeh")
        }
    }

    func testHehVariantsMatchArabicHeh() {
        for heh in ["ہ", "ھ"] {
            XCTAssertTrue(matches("من" + heh, in: "منه آيات"), "\(heh) doesn't match Arabic heh")
        }
    }

    func testHehAndTehMarbutaFormsMatchArabicTehMarbuta() {
        for tehMarbuta in ["ۃ", "ۀ", "ۂ"] {
            XCTAssertTrue(matches("رحم" + tehMarbuta, in: "رحمة من ربك"), "\(tehMarbuta) doesn't match Arabic teh marbuta")
        }
    }

    func testArabicKeyboardStillMatches() {
        XCTAssertTrue(matches("الكتاب", in: "ذلك الكتاب لا ريب فيه"))
        XCTAssertTrue(matches("الذي", in: "الذي خلق"))
    }

    func testUnrelatedTermDoesNotMatch() {
        XCTAssertFalse(matches("کتاب", in: "الحمد لله رب العالمين"))
    }

    func testPersoArabicLettersBecomeWildcardsInThePersistenceQuery() {
        let term = SearchTerm("کتاب")
        XCTAssertEqual(term?.persistenceQueryReplacingArabicSimilarityCharactersWithUnderscore(), "___ب")
    }

    func testCanonicalEncodingsProduceTheSameSearchQuery() throws {
        for suffix in ["\u{06c0}", "\u{06c2}", "\u{06d3}"] {
            let composed = try XCTUnwrap(SearchTerm("رحم" + suffix))
            let decomposed = try XCTUnwrap(SearchTerm("رحم" + suffix.decomposedStringWithCanonicalMapping))
            XCTAssertEqual(Array(composed.persistenceQuery.unicodeScalars), Array(decomposed.persistenceQuery.unicodeScalars))
            XCTAssertEqual(composed.persistenceQueryReplacingArabicSimilarityCharactersWithUnderscore(), decomposed.persistenceQueryReplacingArabicSimilarityCharactersWithUnderscore())
        }
        XCTAssertTrue(matches("رحم\u{06d5}\u{0654}", in: "رحمة"))
        XCTAssertTrue(matches("رحم\u{06c1}\u{0654}", in: "رحمة"))
        XCTAssertTrue(matches("عل\u{06d2}\u{0654}", in: "علي"))
        XCTAssertTrue(matches("علۓ", in: "علئ"))
    }

    func testCanonicalNormalizationPreservesOriginalQuery() throws {
        let input = "cafe\u{0301}"
        let term = try XCTUnwrap(SearchTerm(input))
        XCTAssertEqual(Array(term.compactQuery.unicodeScalars), Array(input.unicodeScalars))
        XCTAssertEqual(Array(term.persistenceQuery.unicodeScalars), Array("café".unicodeScalars))
        XCTAssertTrue(matches(input, in: "café"))
        XCTAssertTrue(matches("café", in: input))
    }

    func testAutocompleteCanRetainItsExistingNormalization() throws {
        let input = "رحم\u{06d5}\u{0654}"
        let term = try XCTUnwrap(SearchTerm(input, normalizeUnicode: false))
        XCTAssertEqual(Array(term.persistenceQuery.unicodeScalars), Array("رحم\u{06d5}".unicodeScalars))
    }

    func testMappedLettersStillMatchOriginalTranslationLetters() {
        for letter in ["ک", "ی", "ے", "ې", "ۍ", "ۓ", "ہ", "ھ", "ۃ", "ۀ", "ۂ"] {
            XCTAssertTrue(matches(letter, in: "لفظ " + letter), letter)
            XCTAssertFalse(matches(letter, in: "ب"), letter)
        }
    }

    func testDistinctConsonantsAreNotMappedToArabicLookalikes() {
        for (input, text) in [("پ", "ب"), ("چ", "ج"), ("ژ", "ز"), ("گ", "ك")] {
            XCTAssertFalse(matches(input, in: text))
            XCTAssertTrue(matches(input, in: input))
        }
    }

    // MARK: Private

    private let verse = Quran.hafsMadani1405.firstVerse

    private func matches(_ term: String, in text: String) -> Bool {
        guard let searchTerm = SearchTerm(term) else {
            return false
        }
        let results = searchTerm.buildSearchResults(verses: [(verse: verse, text: text)])
        return !results.isEmpty
    }
}
