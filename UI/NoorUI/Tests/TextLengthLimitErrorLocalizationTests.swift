//
//  TextLengthLimitErrorLocalizationTests.swift
//
//  Created by Mohamed Afifi on 2026-10-13.
//

import Localization
import QuranAnnotations
import XCTest
@testable import NoorUI

final class TextLengthLimitErrorLocalizationTests: XCTestCase {
    // MARK: Internal

    func test_localizedMessage_namesFieldAndFormattedLimit() {
        XCTAssertEqual(
            TextLengthLimitError(field: .noteBody, bound: .tooShort, limit: 6).localizedMessage,
            "Notes must be at least \(formatted(6)) characters."
        )
        XCTAssertEqual(
            TextLengthLimitError(field: .noteBody, bound: .tooLong, limit: 10000).localizedMessage,
            "Notes can't be longer than \(formatted(10000)) characters."
        )
        XCTAssertEqual(
            TextLengthLimitError(field: .collectionName, bound: .tooShort, limit: 1).localizedMessage,
            "Collection names can't be empty."
        )
        XCTAssertEqual(
            TextLengthLimitError(field: .collectionName, bound: .tooLong, limit: 255).localizedMessage,
            "Collection names can't be longer than \(formatted(255)) characters."
        )
    }

    // MARK: Private

    /// `lFormat` formats the limit for the current region, so the grouping separator varies by machine.
    private func formatted(_ limit: Int) -> String {
        String(format: "%d", locale: .fixedCurrentLocaleNumbers, limit)
    }
}
