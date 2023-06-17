//
//  AsyncAsserts.swift
//
//
//  Created by Mohamed Afifi on 2023-06-03.
//

import Foundation
import XCTest

// Credits to @pointfreeco
// https://github.com/pointfreeco/combine-schedulers
extension Task where Success == Failure, Failure == Never {
    public static func megaYield(count: Int = 10) async {
        for _ in 1 ... count {
            await Task<Void, Never>.detached(priority: .background) { await Task.yield() }.value
        }
    }
}

public func AsyncAssertEqual<T>(
    _ expression1: @autoclosure () async throws -> T,
    _ expression2: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async rethrows where T: Equatable {
    let e1 = try await expression1()
    let e2 = try await expression2()
    XCTAssertEqual(e1, e2, message(), file: file, line: line)
}

public func AsyncAssertThrows(
    _ expression: @autoclosure () async throws -> Void,
    _ expectedError: NSError?,
    _ message: @autoclosure () -> String = "Didn't throw",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        if let expectedError {
            XCTAssertEqual(error as NSError?, expectedError, message(), file: file, line: line)
        }
    }
}

public func AsyncUnwrap<T>(
    _ expression: @autoclosure () async throws -> T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async throws -> T {
    let value = try await expression()
    return try XCTUnwrap(value, message(), file: file, line: line)
}
