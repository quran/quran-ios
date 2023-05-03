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

// Credits to @pointfreeco
// https://github.com/pointfreeco/combine-schedulers
extension Task where Success == Failure, Failure == Never {
    public static func megaYield(count: Int = 10) async {
        for _ in 1 ... count {
            await Task<Void, Never>.detached(priority: .background) { await Task.yield() }.value
        }
    }
}

public func AsyncAssertEqual<T>(_ expression1: @autoclosure () async throws -> T,
                                _ expression2: @autoclosure () async throws -> T,
                                _ message: @autoclosure () -> String = "",
                                file: StaticString = #filePath,
                                line: UInt = #line) async rethrows where T: Equatable
{
    let e1 = try await expression1()
    let e2 = try await expression2()
    XCTAssertEqual(e1, e2, message(), file: file, line: line)
}

public func AsyncAssertThrows(_ expression: @autoclosure () async throws -> Void,
                              _ expectedError: NSError?,
                              _ message: @autoclosure () -> String = "Didn't throw",
                              file: StaticString = #filePath,
                              line: UInt = #line) async
{
    do {
        try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        if let expectedError {
            XCTAssertEqual(error as NSError?, expectedError, message(), file: file, line: line)
        }
    }
}

public func AsyncUnwrap<T>(_ expression: @autoclosure () async throws -> T?,
                           _ message: @autoclosure () -> String = "",
                           file: StaticString = #filePath,
                           line: UInt = #line) async throws -> T
{
    let value = try await expression()
    return try XCTUnwrap(value, message(), file: file, line: line)
}
