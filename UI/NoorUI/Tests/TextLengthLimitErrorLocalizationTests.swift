//
//  TextLengthLimitErrorLocalizationTests.swift
//
//  Created by Mohamed Afifi on 2026-10-13.
//

import QuranAnnotations
import XCTest
@testable import NoorUI

final class TextLengthLimitErrorLocalizationTests: XCTestCase {
    func test_localizedMessage_namesFieldAndFormattedLimit() {
        XCTAssertEqual(
            TextLengthLimitError(field: .noteBody, bound: .tooShort, limit: 6).localizedMessage,
            "Notes must be at least 6 characters."
        )
        XCTAssertEqual(
            TextLengthLimitError(field: .noteBody, bound: .tooLong, limit: 10000).localizedMessage,
            "Notes can't be longer than 10,000 characters."
        )
        XCTAssertEqual(
            TextLengthLimitError(field: .collectionName, bound: .tooShort, limit: 1).localizedMessage,
            "Collection names can't be empty."
        )
        XCTAssertEqual(
            TextLengthLimitError(field: .collectionName, bound: .tooLong, limit: 255).localizedMessage,
            "Collection names can't be longer than 255 characters."
        )
    }
}
