//
//  AnalyticsSettingValueSettingsTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import XCTest
@testable import AppStructureFeature

final class AnalyticsSettingValueSettingsTests: XCTestCase {
    func test_reciter_stripsOnlyALeadingQariPrefix() {
        XCTAssertEqual(AnalyticsSettingValue.reciter(nameKey: "qari_afasy_gapless"), "afasy_gapless")
        XCTAssertEqual(AnalyticsSettingValue.reciter(nameKey: "my_qari_name"), "my_qari_name")
    }
}
