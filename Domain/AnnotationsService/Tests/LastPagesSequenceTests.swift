import XCTest
@testable import AnnotationsService
@testable import QuranAnnotations

final class LastPagesSequenceTests: XCTestCase {
    func test_forwardsValuesAndCompletion() async throws {
        let source = AsyncStream<[LastPage]> { continuation in
            continuation.yield([])
            continuation.finish()
        }
        let sequence = LastPagesSequence(source)
        var iterator = sequence.makeAsyncIterator()

        let value = try await iterator.next()
        let completion = try await iterator.next()

        XCTAssertEqual(value, [])
        XCTAssertNil(completion)
    }

    func test_forwardsErrors() async {
        let source = AsyncThrowingStream<[LastPage], Error> { continuation in
            continuation.finish(throwing: TestError.expected)
        }
        let sequence = LastPagesSequence(source)
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
        let source = AsyncThrowingStream<[LastPage], Error> { continuation in
            continuation.onTermination = { termination in
                guard case .cancelled = termination else { return }
                cancelled.fulfill()
            }
        }
        let sequence = LastPagesSequence(source)
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
        let sequence = LastPagesSequence(SingleValueSequence())
        var first = sequence.makeAsyncIterator()
        var second = sequence.makeAsyncIterator()

        let firstValue = try await first.next()
        let secondValue = try await second.next()
        let firstCompletion = try await first.next()
        let secondCompletion = try await second.next()

        XCTAssertEqual(firstValue, [])
        XCTAssertEqual(secondValue, [])
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

        mutating func next() async -> [LastPage]? {
            guard hasValue else { return nil }
            hasValue = false
            return []
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}
