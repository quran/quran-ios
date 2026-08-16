//
//  AsyncPublisherTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import AsyncAlgorithms
import AsyncUtilitiesForTesting
import Combine
import Utilities
import XCTest

class AsyncPublisherTests: XCTestCase {
    actor Values {
        var results: [Int] = []

        func append(_ number: Int) {
            results.append(number)
        }
    }

    let numbers = [1, 2, 3]
    var subject: PassthroughSubject<Int, Never>!
    var values: Values!

    override func setUp() {
        subject = PassthroughSubject()
        values = Values()
    }

    func test_passThroughSubject_subjectCancellation() async {
        let prefix = 2
        let asyncPublisher = subject.values(bufferingPolicy: .unbounded)

        let task = Task { [iterator = asyncPublisher.makeAsyncIterator()] in
            var iterator = iterator
            while let number = await iterator.next() {
                await values.append(number)
                if await values.results.count == prefix {
                    break
                }
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
            while let number = await iterator.next() {
                await values.append(number)
                await received.send(number)
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

    func test_unbounded() async {
        let numbersPublisher = numbers.publisher
        let asyncPublisher = numbersPublisher.values(bufferingPolicy: .unbounded)

        var results = [Int]()
        for await number in asyncPublisher {
            results.append(number)
        }

        XCTAssertEqual(results, [1, 2, 3])
    }

    func test_bufferingNewest() async {
        let numbersPublisher = numbers.publisher
        let asyncPublisher = numbersPublisher.values(bufferingPolicy: .bufferingNewest(2))

        var iterator = asyncPublisher.makeAsyncIterator()
        let first = await iterator.next()
        let second = await iterator.next()

        // Only the last 2 values should be preserved
        XCTAssertEqual([first, second].compactMap { $0 }, [2, 3])
    }

    func test_bufferingOldest() async {
        let numbersPublisher = numbers.publisher
        let asyncPublisher = numbersPublisher.values(bufferingPolicy: .bufferingOldest(2))

        var iterator = asyncPublisher.makeAsyncIterator()
        let first = await iterator.next()
        let second = await iterator.next()

        // Only the first 2 values should be preserved
        XCTAssertEqual([first, second].compactMap { $0 }, [1, 2])
    }
}
