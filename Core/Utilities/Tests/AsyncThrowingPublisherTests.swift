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

    let numbers = [1, 2, 3]
    let numbersPublisher = [1, 2, 3].publisher.setFailureType(to: PublishingError.self)
    var subject: PassthroughSubject<Int, PublishingError>!
    var channel: AsyncChannel<Void>!
    var values: Values!

    actor Values {
        var error: Error?
        func setError(_ error: Error) {
            self.error = error
        }

        var results: [Int] = []
        func append(_ number: Int) {
            results.append(number)
        }
    }

    override func setUp() {
        subject = PassthroughSubject()
        channel = AsyncChannel()
        values = Values()
    }

    func test_passThroughSubject_failure() async throws {
        let asyncPublisher = subject.values()

        Task {
            do {
                for try await number in asyncPublisher {
                    await values.append(number)
                }
            } catch {
                await values.setError(error)
            }
            await channel.send(())
        }

        // Wait until loop starts.
        await Task.megaYield()

        // Send failure
        subject.send(completion: .failure(.invalid))

        // Wait until the task completes.
        await channel.next()

        await AsyncAssertEqual(await values.error as? PublishingError, PublishingError.invalid)
    }

    func test_passThroughSubject_subjectCancellation() async throws {
        let prefix = 2
        let asyncPublisher = subject.values(bufferingPolicy: .unbounded)

        Task {
            for try await number in asyncPublisher {
                await values.append(number)
                if await values.results.count == prefix {
                    break
                }
            }
            await channel.send(())
        }

        // Wait until loop starts.
        await Task.megaYield()

        for number in numbers {
            subject.send(number)
        }

        // Wait until the break
        await channel.next()

        await AsyncAssertEqual(await values.results, Array(numbers.prefix(2)))
    }

    func test_passThroughSubject_taskCancellation() async throws {
        let asyncPublisher = subject.values(bufferingPolicy: .unbounded)

        let task = Task {
            for try await number in asyncPublisher {
                await values.append(number)
            }
            await values.append(1945)
        }

        // Wait until loop starts.
        await Task.megaYield()

        for number in numbers {
            subject.send(number)
            await Task.megaYield()
        }

        // Cancel the task.
        task.cancel()
        // Wait for cancellation to happen.
        await Task.megaYield()

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

        var results = [Int]()
        for try await number in asyncPublisher {
            results.append(number)
        }

        // Only the last 2 values should be preserved
        XCTAssertEqual(results, [2, 3])
    }

    func test_bufferingOldest() async throws {
        let asyncPublisher = numbersPublisher.values(bufferingPolicy: .bufferingOldest(2))

        var results = [Int]()
        for try await number in asyncPublisher {
            results.append(number)
        }

        // Only the first 2 values should be preserved
        XCTAssertEqual(results, [1, 2])
    }
}
