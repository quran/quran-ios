//
//  AsyncThrowingPublisherTests.swift
//
//
//  Created by Mohamed Afifi on 2023-06-11.
//

import AsyncAlgorithms
import AsyncUtilitiesForTesting
import Combine
import Utilities
import XCTest

class AsyncThrowingPublisherTests: XCTestCase {
    enum PublishingError: Error {
        case invalid
    }

    actor Values {
        var error: Error?
        var results: [Int] = []

        func setError(_ error: Error) {
            self.error = error
        }

        func append(_ number: Int) {
            results.append(number)
        }
    }

    let numbers = [1, 2, 3]
    let numbersPublisher = [1, 2, 3].publisher.setFailureType(to: PublishingError.self)
    var subject: PassthroughSubject<Int, PublishingError>!
    var values: Values!

    override func setUp() {
        subject = PassthroughSubject()
        values = Values()
    }

    func test_passThroughSubject_failure() async {
        let asyncPublisher = subject.values()

        let task = Task { [iterator = asyncPublisher.makeAsyncIterator()] in
            var iterator = iterator
            do {
                while let number = try await iterator.next() {
                    await values.append(number)
                }
            } catch {
                await values.setError(error)
            }
        }

        // Send failure
        subject.send(completion: .failure(.invalid))

        await task.value

        await AsyncAssertEqual(await values.error as? PublishingError, PublishingError.invalid)
    }

    func test_passThroughSubject_subjectCancellation() async {
        let prefix = 2
        let asyncPublisher = subject.values(bufferingPolicy: .unbounded)

        let task = Task { [iterator = asyncPublisher.makeAsyncIterator()] in
            var iterator = iterator
            do {
                while let number = try await iterator.next() {
                    await values.append(number)
                    if await values.results.count == prefix {
                        break
                    }
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        for number in numbers {
            subject.send(number)
        }

        await task.value

        await AsyncAssertEqual(await values.results, Array(numbers.prefix(2)))
    }

    func test_passThroughSubject_taskCancellation() async {
        let asyncPublisher = subject.values(bufferingPolicy: .unbounded)
        let received = AsyncChannel<Int>()

        let task = Task { [iterator = asyncPublisher.makeAsyncIterator()] in
            var iterator = iterator
            do {
                while let number = try await iterator.next() {
                    await values.append(number)
                    await received.send(number)
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            await values.append(1945)
        }

        for number in numbers {
            subject.send(number)
            await AsyncAssertEqual(await received.next(), number)
        }

        task.cancel()
        await task.value

        await AsyncAssertEqual(await values.results, numbers + [1945])
    }

    func test_unbounded() async throws {
        let asyncPublisher = numbersPublisher.values(bufferingPolicy: .unbounded)

        var results = [Int]()
        for try await number in asyncPublisher {
            results.append(number)
        }

        XCTAssertEqual(results, [1, 2, 3])
    }

    func test_bufferingNewest() async throws {
        let asyncPublisher = numbersPublisher.values(bufferingPolicy: .bufferingNewest(2))

        var iterator = asyncPublisher.makeAsyncIterator()
        let first = try await iterator.next()
        let second = try await iterator.next()

        // Only the last 2 values should be preserved
        XCTAssertEqual([first, second].compactMap { $0 }, [2, 3])
    }

    func test_bufferingOldest() async throws {
        let asyncPublisher = numbersPublisher.values(bufferingPolicy: .bufferingOldest(2))

        var iterator = asyncPublisher.makeAsyncIterator()
        let first = try await iterator.next()
        let second = try await iterator.next()

        // Only the first 2 values should be preserved
        XCTAssertEqual([first, second].compactMap { $0 }, [1, 2])
    }
}
