//
//  AyahNumberTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

@testable import QuranKit
import XCTest

final class AyahNumberTests: XCTestCase {
    private let quran = Quran.madani

    func testVerses() throws {
        let verses = quran.verses
        XCTAssertEqual(verses.count, 6236)
        XCTAssertEqual(verses.first!.sura.suraNumber, 1)
        XCTAssertEqual(verses.first!.ayah, 1)
        XCTAssertEqual(verses.last!.sura.suraNumber, 114)
        XCTAssertEqual(verses.last!.ayah, 6)
        XCTAssertEqual(verses[21].sura.suraNumber, 2)
        XCTAssertEqual(verses[21].ayah, 15)

        XCTAssertEqual(verses[0].description, "<AyahNumber sura=1 ayah=1>")
        XCTAssertEqual(verses[29].description, "<AyahNumber sura=2 ayah=23>")

        XCTAssertEqual(verses[1], verses[0].next)
        XCTAssertEqual(verses[29], verses[28].next)
        XCTAssertEqual(verses[29], verses[27].next?.next)
        XCTAssertNil(verses.last!.next)

        XCTAssertEqual(verses[6].sura.suraNumber, 1)
        XCTAssertEqual(verses[6].next?.sura.suraNumber, 2)
        XCTAssertEqual(verses[6].next, verses[7])

        XCTAssertEqual(verses[7].sura.suraNumber, 2)
        XCTAssertEqual(verses[7].previous?.sura.suraNumber, 1)
        XCTAssertEqual(verses[7].previous, verses[6])

        XCTAssertEqual(verses[0], verses[1].previous)
        XCTAssertEqual(verses[28], verses[29].previous)
        XCTAssertEqual(verses[27], verses[29].previous?.previous)
        XCTAssertNil(verses[0].previous)

        XCTAssertEqual(verses[29].page.pageNumber, 4)
        XCTAssertEqual(verses[3].page.pageNumber, 1)
        XCTAssertEqual(verses[6235].page.pageNumber, 604)

        XCTAssertEqual(verses[4].array(to: verses[4]), [verses[4]])
        XCTAssertEqual(verses[4].array(to: verses[10]), Array(verses[4 ... 10]))
        XCTAssertEqual(verses[0].array(to: verses[6235]), verses)
    }
}
