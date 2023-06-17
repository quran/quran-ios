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
    private var service: SearchRecentsService!
    private let preferences = RecentSearchPreferences.shared
    private let userDefaults = UserDefaults.standard

    override func setUpWithError() throws {
        service = SearchRecentsService()
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }

    func testPopularTerms() {
        assertSnapshot(matching: service.getPopularTerms(), as: .json)

        preferences.recentSearchItems = ["1", "2"]
        assertSnapshot(matching: service.getPopularTerms(), as: .json)

        // popular items are removed when there are 3 recents
        preferences.recentSearchItems = ["1", "2", "3"]
        XCTAssertEqual(service.getPopularTerms(), [])
    }

    func testRecents() {
        XCTAssertEqual(service.getRecents(), [])

        // adding elements in sorted way
        service.addToRecents("1")
        service.addToRecents("4")
        XCTAssertEqual(service.getRecents(), ["4", "1"])

        // repeated elements are moved to the front
        service.addToRecents("3")
        service.addToRecents("1")
        service.addToRecents("5")
        XCTAssertEqual(service.getRecents(), ["5", "1", "3", "4"])

        //
        service.addToRecents("6")
        service.addToRecents("7")
        XCTAssertEqual(service.getRecents(), ["7", "6", "5", "1", "3"])
    }
}
