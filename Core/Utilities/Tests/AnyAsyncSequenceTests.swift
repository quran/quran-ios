import XCTest
@testable import Utilities

final class AnyAsyncSequenceTests: XCTestCase {
    func test_forwardsValuesAndCompletion() async throws {
        let source = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        }
        let sequence = AnyAsyncSequence(source)
        var iterator = sequence.makeAsyncIterator()

        let value = try await iterator.next()
        let completion = try await iterator.next()

        XCTAssertEqual(value, 1)
        XCTAssertNil(completion)
    }

    func test_forwardsErrors() async {
        let source = AsyncThrowingStream<Int, Error> { continuation in
            continuation.finish(throwing: TestError.expected)
        }
        let sequence = AnyAsyncSequence(source)
        var iterator = sequence.makeAsyncIterator()

        do {
            _ = try await iterator.next()
            XCTFail("Expected the source error")
        } catch {
            XCTAssertEqual(error as? TestError, .expected)
        }
    }

    func test_forwardsCancellation() async {
        let cancelled = expectation(description: "Source receives cancellation")
        let source = AsyncThrowingStream<Int, Error> { continuation in
            continuation.onTermination = { termination in
                guard case .cancelled = termination else { return }
                cancelled.fulfill()
            }
        }
        let sequence = AnyAsyncSequence(source)
        let observation = Task {
            var iterator = sequence.makeAsyncIterator()
            _ = try await iterator.next()
        }

        await Task.yield()
        observation.cancel()

        await fulfillment(of: [cancelled], timeout: 1)
        _ = await observation.result
    }

    func test_iteratorsOwnIndependentSourceIterators() async throws {
        let sequence = AnyAsyncSequence(SingleValueSequence())
        var first = sequence.makeAsyncIterator()
        var second = sequence.makeAsyncIterator()

        let firstValue = try await first.next()
        let secondValue = try await second.next()
        let firstCompletion = try await first.next()
        let secondCompletion = try await second.next()

        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(secondValue, 1)
        XCTAssertNil(firstCompletion)
        XCTAssertNil(secondCompletion)
    }
}

private enum TestError: Error {
    case expected
}

private struct SingleValueSequence: AsyncSequence {
    struct AsyncIterator: AsyncIteratorProtocol {
        var hasValue = true

        mutating func next() async -> Int? {
            guard hasValue else { return nil }
            hasValue = false
            return 1
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}
