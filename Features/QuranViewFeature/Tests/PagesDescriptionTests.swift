//
//  PagesDescriptionTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import QuranKit
import XCTest
@testable import QuranViewFeature

final class PagesDescriptionTests: XCTestCase {
    // MARK: Internal

    func testOnePage() {
        XCTAssertEqual([quran.pages[1]].localizedDescription(language: .english), "Page 2, Juz' 1")
    }

    func testTwoPagesShowARange() {
        let pages = [quran.pages[1], quran.pages[2]]

        XCTAssertEqual(pages.localizedDescription(language: .english), "Pages 2–3, Juz' 1")
        XCTAssertEqual(
            withoutBidiIsolates(pages.localizedDescription(language: .arabic)),
            "صفحات 2–3، جزء 1"
        )
        XCTAssertEqual(pages.localizedDescription(language: .chinese), "第1卷，第2至3页")
    }

    func testTwoPagesAcrossJuzsShowTheFirstJuz() {
        let pages = [quran.pages[20], quran.pages[21]]

        XCTAssertEqual(pages.localizedDescription(language: .english), "Pages 21–22, Juz' 1")
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    /// Foundation wraps `%@` arguments of a right-to-left format in U+2068/U+2069 bidi isolates.
    private func withoutBidiIsolates(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{2068}", with: "").replacingOccurrences(of: "\u{2069}", with: "")
    }
}
