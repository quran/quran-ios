//
//  QuartersDataRetrieverTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-06.
//

import QuranKit
import XCTest
@testable import QuranTextKit

final class QuartersDataRetrieverTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    func testQuarterLocalization() {
        XCTAssertEqual("Hizb 1", quran.quarters[0].localizedName)
        XCTAssertEqual("¼ Hizb 1", quran.quarters[1].localizedName)
        XCTAssertEqual("½ Hizb 1", quran.quarters[2].localizedName)
        XCTAssertEqual("¾ Hizb 1", quran.quarters[3].localizedName)
        XCTAssertEqual("Hizb 2", quran.quarters[4].localizedName)
    }

    func testPageQuarterInfo() {
        XCTAssertEqual("Juz' 1, Hizb 1", quran.pages[0].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[1].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[2].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[3].localizedQuarterName)
        XCTAssertEqual("Juz' 1, ¼ Hizb 1", quran.pages[4].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[5].localizedQuarterName)
        XCTAssertEqual("Juz' 1, ½ Hizb 1", quran.pages[6].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[7].localizedQuarterName)
        XCTAssertEqual("Juz' 1, ¾ Hizb 1", quran.pages[8].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[9].localizedQuarterName)
        XCTAssertEqual("Juz' 1, Hizb 2", quran.pages[10].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[11].localizedQuarterName)
        XCTAssertEqual("Juz' 30, ¾ Hizb 60", quran.pages[598].localizedQuarterName)
        XCTAssertEqual("Juz' 30", quran.pages[599].localizedQuarterName)
    }
}
