//
//  String+ExtensionTests.swift
//
//
//  Created by Mohamed Afifi on 2024-01-01.
//

import Foundation
import Utilities
import XCTest

class StringExtensionTests: XCTestCase {
    let regex = try! NSRegularExpression(pattern: #"\{\{.*?\}\}"#)

    var incrementReplace: (Substring, Int) -> String {
        { _, index in "(\(index + 1))" }
    }

    func test_replaceMatches_english() {
        let text = "Hello world{{some reference}}! Good morning{{another reference}}{{reference}}"
        let (modifiedText, ranges) = text.replaceMatches(of: regex, replace: incrementReplace)

        let expectedText = "Hello world(1)! Good morning(2)(3)"
        XCTAssertEqual(modifiedText, expectedText)
        assertRanges(text: modifiedText, ranges: ranges, values: ["(1)", "(2)", "(3)"])
    }

    func test_replaceMatches_emojis() {
        let text = "Hello world{{some reference}}! ✔️ Good morning{{another reference}}{{reference}}"
        let (modifiedText, ranges) = text.replaceMatches(of: regex, replace: incrementReplace)

        let expectedText = "Hello world(1)! ✔️ Good morning(2)(3)"
        XCTAssertEqual(modifiedText, expectedText)
        assertRanges(text: modifiedText, ranges: ranges, values: ["(1)", "(2)", "(3)"])
    }

    func test_replaceMatches_noMatches() {
        let text = "Hello world!"
        let (modifiedText, ranges) = text.replaceMatches(of: regex, replace: incrementReplace)

        let expectedText = "Hello world!"
        XCTAssertEqual(modifiedText, expectedText)
        XCTAssertEqual(ranges.count, 0)
    }

    func test_replaceMatches_emojiInMatch() {
        let text = "{{a🛑🛑}}Hello {{🛑b🛑}}world!{{🛑🛑c🛑}}"
        let (modifiedText, ranges) = text.replaceMatches(of: regex, replace: incrementReplace)

        let expectedText = "(1)Hello (2)world!(3)"
        XCTAssertEqual(modifiedText, expectedText)
        assertRanges(text: modifiedText, ranges: ranges, values: ["(1)", "(2)", "(3)"])
    }

    func test_replaceMatches_onlyMatches() {
        let text = "{{a🛑🛑}}"
        let (modifiedText, ranges) = text.replaceMatches(of: regex, replace: incrementReplace)

        let expectedText = "(1)"
        XCTAssertEqual(modifiedText, expectedText)
        assertRanges(text: modifiedText, ranges: ranges, values: ["(1)"])
    }

    func assertRanges(text: String, ranges: [Range<String.Index>], values: [String], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(ranges.map { String(text[$0]) }, values, file: file, line: line)
    }
}
