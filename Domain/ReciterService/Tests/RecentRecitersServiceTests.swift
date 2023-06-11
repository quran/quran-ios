//
//  RecentRecitersServiceTests.swift
//
//
//  Created by Zubair Khan on 12/5/22.
//

import Foundation
import Reciter
@testable import ReciterService
import XCTest

class RecentRecitersServiceTests: XCTestCase {
    private var service: RecentRecitersService!
    private let userDefaults = UserDefaults.standard

    override func setUpWithError() throws {
        service = RecentRecitersService()
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }

    func testRecentReciters() {
        let reciter1 = createReciter(id: 1)
        let reciter2 = createReciter(id: 2)
        let reciter3 = createReciter(id: 3)
        let reciter4 = createReciter(id: 4)
        let reciter5 = createReciter(id: 5)
        let invalidReciter = createReciter(id: 6)

        let allReciters: [Reciter] = Array(arrayLiteral: reciter1, reciter2, reciter3, reciter4, reciter5)

        // Test empty reciters list is returned when none are added
        XCTAssertEqual(getRecentRecitersIds(allReciters), [])

        // Edge case: if recentReciterIds ends up with an ID that's not present in allReciters
        service.updateRecentRecitersList(invalidReciter)
        XCTAssertEqual(getRecentRecitersIds(allReciters), [])

        // Add one reciter
        service.updateRecentRecitersList(reciter1)
        XCTAssertEqual(getRecentRecitersIds(allReciters), [1])

        // Add two more reciters
        service.updateRecentRecitersList(reciter2)
        service.updateRecentRecitersList(reciter3)
        XCTAssertEqual(getRecentRecitersIds(allReciters), [3, 2, 1])

        // Add one more and make sure we do not exceed more than 3 recent reciters
        service.updateRecentRecitersList(reciter4)
        XCTAssertEqual(getRecentRecitersIds(allReciters), [4, 3, 2])

        // make reciter3 be the most recent
        service.updateRecentRecitersList(reciter3)
        XCTAssertEqual(getRecentRecitersIds(allReciters), [3, 4, 2])

        // repeatedly selecting the same reciter should not remove others
        service.updateRecentRecitersList(reciter4)
        service.updateRecentRecitersList(reciter4)
        service.updateRecentRecitersList(reciter4)
        XCTAssertEqual(getRecentRecitersIds(allReciters), [4, 3, 2])
    }

    private func getRecentRecitersIds(_ allReciters: [Reciter]) -> [Int] {
        service.recentReciters(allReciters).map(\.id)
    }

    private func createReciter(id: Int) -> Reciter {
        let name: String = "reciter" + String(id)
        return Reciter(id: id,
                       nameKey: name,
                       directory: "dir",
                       audioURL: URL(validURL: "http://example.com"),
                       audioType: .gapless(databaseName: name),
                       hasGaplessAlternative: false,
                       category: .arabic)
    }
}
