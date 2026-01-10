//
//  SearchRecentsServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-18.
//

import SnapshotTesting
import XCTest
@testable import QuranTextKit

class SearchRecentsServiceTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        service = SearchRecentsService.shared
        service.reset()
    }

    func testPopularTerms() {
        assertSnapshot(of: service.popularTerms, as: .json)

        service.recentSearchItems = ["1", "2"]
        assertSnapshot(of: service.popularTerms, as: .json)
    }

    func testRecents() {
        XCTAssertEqual(service.recentSearchItems, [])

        // adding elements in sorted way
        service.addToRecents("1")
        service.addToRecents("4")
        XCTAssertEqual(service.recentSearchItems, ["4", "1"])

        // repeated elements are moved to the front
        service.addToRecents("3")
        service.addToRecents("1")
        service.addToRecents("5")
        XCTAssertEqual(service.recentSearchItems, ["5", "1", "3", "4"])

        service.addToRecents("6")
        service.addToRecents("7")
        XCTAssertEqual(service.recentSearchItems, ["7", "6", "5", "1", "3"])
    }

    // MARK: Private

    private var service: SearchRecentsService!
}
