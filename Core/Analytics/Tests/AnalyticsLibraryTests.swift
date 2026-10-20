//
//  AnalyticsLibraryTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import XCTest

final class AnalyticsLibraryTests: XCTestCase {
    func test_defaultRequirements_doNotLogSingleValueEvents() {
        let library = SingleValueLibrary()

        library.logEvent("Event", parameters: ["key": .string("value")])
        library.setUserProperty("on", for: .audioStreaming)

        XCTAssertEqual(library.loggedNames, [])
    }
}

private final class SingleValueLibrary: AnalyticsLibrary, @unchecked Sendable {
    private(set) var loggedNames: [String] = []

    func logEvent(_ name: String, value _: String) {
        loggedNames.append(name)
    }
}
