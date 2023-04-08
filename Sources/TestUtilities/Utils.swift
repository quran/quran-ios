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

    public func wait<Future: Thenable>(for promise: Future, timeout: TimeInterval = defaultTimeout, file: StaticString = #filePath, line: UInt = #line) throws -> Future.T {
        let expectation = expectation(description: "promise")
        var result: Swift.Result<Future.T, Error>?
        promise.done { value in
            result = .success(value)
            expectation.fulfill()
        }
        .catch { error in
            result = .failure(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        let unboxedResult = try XCTUnwrap(result, file: file, line: line)
        return try unboxedResult.get()
    }

    public func wait(for queue: OperationQueue, timeout: TimeInterval = defaultTimeout) {
        if queue.operationCount == 0 {
            return
        }
        let expectation = keyValueObservingExpectation(for: queue, keyPath: #keyPath(OperationQueue.operationCount)) { _, _ in
            queue.operationCount == 0
        }

        wait(for: [expectation], timeout: timeout)
    }

    @nonobjc
    public func wait(for queue: DispatchQueue, timeout: TimeInterval = defaultTimeout) {
        let expectation = expectation(description: "DispatchQueue")
        queue.async(flags: .barrier) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // From: https://www.swiftbysundell.com/articles/testing-error-code-paths-in-swift/
    public func assert<T, E: Error & Equatable>(
        _ expression: @autoclosure () throws -> T,
        throws error: E,
        in file: StaticString = #file,
        line: UInt = #line
    ) {
        var thrownError: Error?

        XCTAssertThrowsError(try expression(),
                             file: file, line: line) {
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
