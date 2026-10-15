//
//  PlainTextPartViewTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import XCTest
@testable import NoorUI

final class PlainTextPartViewTests: XCTestCase {
    func test_splittingTrailingSpace_splitsSpaceAndIsolates() {
        let split = PlainTextPartView.splittingTrailingSpace("عند \u{2068}")

        XCTAssertEqual(split.content, "عند")
        XCTAssertEqual(split.trailingSpace, " \u{2068}")
    }

    func test_splittingTrailingSpace_keepsTrailingTagSequenceFlagWhole() {
        let england = "\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}"

        let split = PlainTextPartView.splittingTrailingSpace("x \(england)")

        XCTAssertEqual(split.content, "x \(england)")
        XCTAssertEqual(split.trailingSpace, "")
    }

    func test_splittingTrailingSpace_keepsTrailingZeroWidthJoinerWhole() {
        let split = PlainTextPartView.splittingTrailingSpace("عند\u{200D}")

        XCTAssertEqual(split.content, "عند\u{200D}")
        XCTAssertEqual(split.trailingSpace, "")
    }

    func test_splittingTrailingSpace_doesNotSplitWhitespaceOnlyText() {
        let split = PlainTextPartView.splittingTrailingSpace(" \u{2069}")

        XCTAssertEqual(split.content, " \u{2069}")
        XCTAssertEqual(split.trailingSpace, "")
    }

    func test_splittingTrailingSpace_doesNotSplitEmptyText() {
        let split = PlainTextPartView.splittingTrailingSpace("")

        XCTAssertEqual(split.content, "")
        XCTAssertEqual(split.trailingSpace, "")
    }
}
