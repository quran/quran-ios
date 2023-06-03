//
//  XCTestCase+Publisher.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import Combine
import XCTest

extension XCTestCase {
    public func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
        var result: Result<T.Output, Error>?
        let expectation = expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        // Just like before, we await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }

    public func awaitPublisher<T: Publisher>(
        _ publisher: T,
        numberOfElements: Int,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> [T.Output]
        where T.Failure == Never
    {
        var elements: [T.Output] = []
        let expectation = expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink { value in
            elements.append(value)
            if elements.count == numberOfElements {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        if elements.count < numberOfElements {
            XCTFail("Received less than \(numberOfElements) elements \(elements)")
        }

        return elements
    }

    public func awaitSingleItemPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output
        where T.Failure == Never
    {
        let elements = try awaitPublisher(
            publisher,
            numberOfElements: 1,
            timeout: timeout,
            file: file, line: line
        )
        return elements[0]
    }
}
