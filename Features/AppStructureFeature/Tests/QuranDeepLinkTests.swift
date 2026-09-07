//
//  QuranDeepLinkTests.swift
//  Quran
//
//  Created by Abdullah Levin on 2026-09-06.
//

import QuranKit
import XCTest
@testable import AppStructureFeature

final class QuranDeepLinkTests: XCTestCase {
    // MARK: Internal

    func testSuraOnlyLink() {
        XCTAssertEqual(deepLink("quran://2"), .sura(sura(2)))
    }

    func testSuraAndAyahLink() {
        XCTAssertEqual(deepLink("quran://2/255"), .ayah(ayah(sura: 2, ayah: 255)))
    }

    func testLegacySchemeIsSupported() {
        XCTAssertEqual(deepLink("quran-ios://114/6"), .ayah(ayah(sura: 114, ayah: 6)))
    }

    func testSchemeIsCaseInsensitive() {
        XCTAssertEqual(deepLink("QURAN://1/1"), .ayah(ayah(sura: 1, ayah: 1)))
    }

    func testTrailingSlashIsIgnored() {
        XCTAssertEqual(deepLink("quran://18/"), .sura(sura(18)))
    }

    func testNonNumericSegmentsAreSkipped() {
        XCTAssertEqual(deepLink("quran://sura/2/255"), .ayah(ayah(sura: 2, ayah: 255)))
    }

    func testExtraSegmentsAreIgnored() {
        XCTAssertEqual(deepLink("quran://2/255/anything"), .ayah(ayah(sura: 2, ayah: 255)))
    }

    func testFirstAndLastAyahOfTheQuran() {
        XCTAssertEqual(deepLink("quran://1/1"), .ayah(quran.firstVerse))
        XCTAssertEqual(deepLink("quran://114/6"), .ayah(quran.lastVerse))
    }

    func testUnsupportedSchemeIsRejected() {
        XCTAssertNil(deepLink("https://quran.com/2/255"))
        XCTAssertNil(deepLink("quranx://2/255"))
    }

    func testLinkWithoutSuraIsRejected() {
        XCTAssertNil(deepLink("quran://"))
        XCTAssertNil(deepLink("quran://home"))
    }

    func testSuraOutOfRangeIsRejected() {
        XCTAssertNil(deepLink("quran://0"))
        XCTAssertNil(deepLink("quran://115"))
        XCTAssertNil(deepLink("quran://999"))
    }

    func testAyahOutOfRangeIsRejected() {
        XCTAssertNil(deepLink("quran://2/0"))
        XCTAssertNil(deepLink("quran://2/287"))
        XCTAssertNil(deepLink("quran://1/8"))
    }

    func testLastAyahOfSuraIsAccepted() {
        XCTAssertEqual(deepLink("quran://2/286"), .ayah(ayah(sura: 2, ayah: 286)))
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    private func deepLink(_ string: String) -> QuranDeepLink? {
        guard let url = URL(string: string) else {
            XCTFail("Couldn't create a URL out of \(string)")
            return nil
        }
        return QuranDeepLink(url: url, quran: quran)
    }

    private func sura(_ suraNumber: Int) -> Sura {
        Sura(quran: quran, suraNumber: suraNumber)!
    }

    private func ayah(sura suraNumber: Int, ayah ayahNumber: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: suraNumber, ayah: ayahNumber)!
    }
}
