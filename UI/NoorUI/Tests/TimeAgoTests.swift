//
//  TimeAgoTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import XCTest
@testable import NoorUI

final class TimeAgoTests: XCTestCase {
    // MARK: Internal

    func test_justSaved_readsNow() {
        XCTAssertEqual(english.string(for: now, relativeTo: now), "now")
        XCTAssertEqual(english.string(for: now.addingTimeInterval(-30), relativeTo: now), "now")
        XCTAssertEqual(english.string(for: now.addingTimeInterval(-59), relativeTo: now), "now")
    }

    func test_futureDate_readsNow() {
        XCTAssertEqual(english.string(for: now.addingTimeInterval(0.3), relativeTo: now), "now")
        XCTAssertEqual(english.string(for: now.addingTimeInterval(5 * minute), relativeTo: now), "now")
    }

    func test_pastDates_readRelative() {
        XCTAssertEqual(english.string(for: now.addingTimeInterval(-minute), relativeTo: now), "1 minute ago")
        XCTAssertEqual(english.string(for: now.addingTimeInterval(-5 * minute), relativeTo: now), "5 minutes ago")
        XCTAssertEqual(english.string(for: now.addingTimeInterval(-day), relativeTo: now), "yesterday")
        XCTAssertEqual(english.string(for: now.addingTimeInterval(-3 * day), relativeTo: now), "3 days ago")
    }

    func test_olderThanThirtyDays_readsFullDate() {
        // Noon UTC on April 15th, so it stays in April 2026 in every time zone.
        let result = english.string(for: now.addingTimeInterval(-31 * day), relativeTo: now)

        XCTAssertTrue(result.contains("April"), result)
        XCTAssertTrue(result.hasSuffix("2026"), result)
    }

    func test_justSaved_readsNowInArabic() {
        let arabic = TimeAgoFormatter(locale: Locale(identifier: "ar"))

        XCTAssertEqual(arabic.string(for: now, relativeTo: now), "الآن")
    }

    // MARK: Private

    private let minute: TimeInterval = 60
    private let day: TimeInterval = 60 * 60 * 24
    private let now = ISO8601DateFormatter().date(from: "2026-05-16T12:00:00Z")!
    private let english = TimeAgoFormatter(locale: Locale(identifier: "en"))
}
