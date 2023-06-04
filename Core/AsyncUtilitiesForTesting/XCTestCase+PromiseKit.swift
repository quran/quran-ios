//
//  Utils.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import PromiseKit
import XCTest

extension XCTestCase {
    public static let defaultTimeout: TimeInterval = 5

    @nonobjc
    public func wait(for queue: DispatchQueue, timeout: TimeInterval = defaultTimeout) {
        let expectation = expectation(description: "DispatchQueue")
        queue.async(flags: .barrier) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // From: https://www.swiftbysundell.com/articles/testing-error-code-paths-in-swift/
    public func assert<E: Error & Equatable>(
        _ expression: @autoclosure () throws -> some Any,
        throws error: E,
        in file: StaticString = #file,
        line: UInt = #line
    ) {
        var thrownError: Error?

        XCTAssertThrowsError(try expression(),
                             file: file, line: line)
        {
            thrownError = $0
        }

        XCTAssertTrue(
            thrownError is E,
            "Unexpected error type: \(type(of: thrownError))",
            file: file, line: line
        )

        XCTAssertEqual(
            thrownError as? E, error,
            file: file, line: line
        )
    }
}
