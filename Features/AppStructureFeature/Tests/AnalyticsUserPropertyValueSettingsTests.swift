//
//  AnalyticsUserPropertyValueSettingsTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import XCTest
@testable import AppStructureFeature

final class AnalyticsUserPropertyValueSettingsTests: XCTestCase {
    func test_reciter_stripsOnlyALeadingQariPrefix() {
        XCTAssertEqual(AnalyticsUserPropertyValue.reciter(nameKey: "qari_afasy_gapless"), "afasy_gapless")
        XCTAssertEqual(AnalyticsUserPropertyValue.reciter(nameKey: "my_qari_name"), "my_qari_name")
    }
}
