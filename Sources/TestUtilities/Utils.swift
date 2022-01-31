//
//  Utils.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import PromiseKit
import XCTest

extension XCTestCase {
    @nonobjc
    public func wait<Future: Thenable>(for promise: Future, timeout: TimeInterval = 1) -> Future.T? {
        let expectation = expectation(description: "promise")
        var result: Future.T?
        promise.done { value in
            result = value
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Promise failed!")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        return result
    }

    public func wait(for queue: OperationQueue, timeout: TimeInterval = 1) {
        if queue.operationCount == 0 {
            return
        }
        let expectation = keyValueObservingExpectation(for: queue, keyPath: #keyPath(OperationQueue.operationCount)) { _, _ in
            queue.operationCount == 0
        }

        wait(for: [expectation], timeout: timeout)
    }

    @nonobjc
    public func wait(for queue: DispatchQueue, timeout: TimeInterval = 1) {
        let expectation = expectation(description: "DispatchQueue")
        queue.async(flags: .barrier) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
}
