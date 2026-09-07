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
        for yeh in ["ی", "ے", "ې", "ۍ"] {
            XCTAssertTrue(matches("الذ" + yeh, in: "الذي خلق"), "\(yeh) doesn't match Arabic yeh")
        }
    }

    func testHehVariantsMatchArabicHeh() {
        for heh in ["ہ", "ھ"] {
            XCTAssertTrue(matches("من" + heh, in: "منه آيات"), "\(heh) doesn't match Arabic heh")
        }
    }

    func testTehMarbutaVariantsMatchArabicTehMarbuta() {
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
