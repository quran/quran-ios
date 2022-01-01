//
//  Utils.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import PromiseKit
import XCTest

extension XCTestCase {
    func wait<T>(for promise: Promise<T>) -> T? {
        let expectation = expectation(description: "promise")
        var result: T?
        promise.done { value in
            result = value
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Promise failed!")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        return result
    }
}
