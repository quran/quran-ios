//
//  TestResourcePathTests.swift
//
//

import XCTest
@testable import NoorUI

final class TestResourcePathTests: XCTestCase {
    func testResourceURLPointsToExistingResource() {
        let url = testResourceURL("images/page604.png")

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), url.path)
    }
}
