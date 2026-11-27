//
//  FootnoteVerseReferenceTests.swift
//

import XCTest
@testable import QuranTranslationFeature

final class FootnoteVerseReferenceTests: XCTestCase {
    func testFindsReferencesInBraces() {
        XCTAssertEqual(
            references(in: "See footnote for {6:38}. (V.{3:85}) (Verse {2:76}) [See also V.{30:30}] Lihat surah An-Nisāʼ {4:48}."),
            ["{6:38} → 6:38", "{3:85} → 3:85", "{2:76} → 2:76", "{30:30} → 30:30", "{4:48} → 4:48"]
        )
    }

    func testIncludesARangeEndInTheReference() {
        XCTAssertEqual(
            references(in: "See {21:51}-71 for the full story (see {7:16}-17, {15:39}–40, and {38:82} - 83)."),
            ["{21:51}-71 → 21:51", "{7:16}-17 → 7:16", "{15:39}–40 → 15:39", "{38:82} - 83 → 38:82"]
        )
    }

    func testReadsDigitsInAnyScriptAndSpacesInsideTheBraces() {
        XCTAssertEqual(references(in: "{٦:٣٨} and { 2 : 255 }"), ["{٦:٣٨} → 6:38", "{ 2 : 255 } → 2:255"])
    }

    func testLeavesOutBibleReferences() {
        XCTAssertEqual(references(in: "Some scholars cite Deuteronomy {18:15}-18 and {33:2}, Isaiah 42, and John {14:16}."), [])
        XCTAssertEqual(references(in: "e.g. Deut. {18:18},{21:21}; Psl. {118:22}-23; Hab.{3:3}-4; Jn.{14:12}-17, {14:26}-28, {16:7}-14."), [])
        XCTAssertEqual(references(in: "He had many wives (1 Kings {11:3})."), [])
    }

    func testKeepsReferencesAfterABibleReference() {
        XCTAssertEqual(references(in: "(Luke {20:25}). Compare the Quran, {9:29}."), ["{9:29} → 9:29"])
    }

    func testKeepsReferencesAfterProphetsNamedLikeBibleBooks() {
        XCTAssertEqual(
            references(in: "See the story of Jonah {37:139}-148 and Job {38:41}."),
            ["{37:139}-148 → 37:139", "{38:41} → 38:41"]
        )
    }

    func testLeavesOutBracesInArabicScript() {
        XCTAssertEqual(references(in: "دیکھیے خروج {20:5}۔ 21 {11:14}"), [])
    }

    func testIgnoresReferencesWithoutBraces() {
        XCTAssertEqual(references(in: "See 2:255, verse 12, 3/4 and {2:}."), [])
    }

    private func references(in text: String) -> [String] {
        text.footnoteVerseReferences().map { "\(text[$0.range]) → \($0.sura):\($0.ayah)" }
    }
}
