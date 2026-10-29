import XCTest
@testable import Utilities

final class FlatMapLatestTests: XCTestCase {
    func test_switching_yieldsOnlyTheLatestInnerValues() async throws {
        let outer = ControlledStream<Int>()
        let inners = Inners()
        var iterator = outer.stream.flatMapLatest { inners.make($0) }.makeAsyncIterator()

        outer.yield(1)
        try await inners.continuation(1).yield("1a")
        let first = try await iterator.next()
        outer.yield(2)
        await waitUntil { inners.isTerminated(1) }
        try await inners.continuation(2).yield("2a")
        let second = try await iterator.next()

        XCTAssertEqual(first, "1a")
        XCTAssertEqual(second, "2a")
    }

    func test_supersededInnerValues_areNeverDelivered() async throws {
        let outer = ControlledStream<Int>()
        let inners = Inners()
        let stubborn = StubbornSequence()
        var iterator = outer.stream.flatMapLatest { element -> AnyAsyncSequence<String> in
            element == 1 ? AnyAsyncSequence(stubborn) : AnyAsyncSequence(inners.make(element))
        }.makeAsyncIterator()

        outer.yield(1)
        await waitUntil { stubborn.isWaiting }
        outer.yield(2)
        try await inners.continuation(2).yield("fresh")
        let fresh = try await iterator.next()
        await stubborn.gate.open()
        await waitUntil { stubborn.didReturnStaleValue }
        outer.finish()
        try await inners.continuation(2).finish()
        let completion = try await iterator.next()

        XCTAssertEqual(fresh, "fresh")
        XCTAssertNil(completion)
    }

    func test_switching_dropsUnconsumedValuesOfTheSupersededInner() async throws {
        let outer = ControlledStream<Int>()
        let inners = Inners()
        var iterator = outer.stream.flatMapLatest { inners.make($0) }.makeAsyncIterator()

        outer.yield(1)
        try await inners.continuation(1).yield("1a")
        // A second pull means "1a" was already buffered for the consumer.
        await waitUntil { inners.pulls(1) >= 2 }
        outer.yield(2)
        await waitUntil { inners.isTerminated(1) }
        try await inners.continuation(2).yield("2a")
        let value = try await iterator.next()

        XCTAssertEqual(value, "2a")
    }

    func test_innerError_finishesTheStreamAndCancelsTheOuterSequence() async throws {
        let outer = ControlledStream<Int>()
        let inners = Inners()
        var iterator = outer.stream.flatMapLatest { inners.make($0) }.makeAsyncIterator()

        outer.yield(1)
        let inner = try await inners.continuation(1)
        inner.yield("a")
        inner.finish(throwing: TestError.expected)

        let value = try await iterator.next()
        await assertThrows(TestError.expected) { _ = try await iterator.next() }
        await waitUntil { outer.isTerminated }
        XCTAssertEqual(value, "a")
    }

    func test_outerError_finishesTheStreamAndCancelsTheInnerSequence() async throws {
        let outer = ControlledThrowingStream<Int>()
        let inners = Inners()
        var iterator = outer.stream.flatMapLatest { inners.make($0) }.makeAsyncIterator()

        outer.continuation.yield(1)
        _ = try await inners.continuation(1)
        outer.continuation.finish(throwing: TestError.expected)

        await assertThrows(TestError.expected) { _ = try await iterator.next() }
        await waitUntil { inners.isTerminated(1) }
    }

    func test_finishes_onlyAfterOuterAndLatestInnerFinish() async throws {
        let outer = ControlledStream<Int>()
        let inners = Inners()
        var iterator = outer.stream.flatMapLatest { inners.make($0) }.makeAsyncIterator()

        outer.yield(1)
        try await inners.continuation(1).yield("1a")
        try await inners.continuation(1).finish()
        let afterInnerFinished = try await iterator.next()
        outer.yield(2)
        outer.finish()
        try await inners.continuation(2).yield("2a")
        let afterOuterFinished = try await iterator.next()
        try await inners.continuation(2).finish()
        let completion = try await iterator.next()

        XCTAssertEqual(afterInnerFinished, "1a")
        XCTAssertEqual(afterOuterFinished, "2a")
        XCTAssertNil(completion)
    }

    func test_finishes_whenOuterFinishesWithoutElements() async throws {
        let outer = ControlledStream<Int>()
        var iterator = outer.stream.flatMapLatest { _ in AsyncStream<String> { _ in } }.makeAsyncIterator()

        outer.finish()
        let completion = try await iterator.next()

        XCTAssertNil(completion)
    }

    func test_consumerCancellation_cancelsOuterAndInnerSequences() async throws {
        let outer = ControlledStream<Int>()
        let inners = Inners()
        let sequence = outer.stream.flatMapLatest { inners.make($0) }
        let consumer = Task {
            for try await _ in sequence {}
        }

        outer.yield(1)
        _ = try await inners.continuation(1)
        consumer.cancel()

        await waitUntil { inners.isTerminated(1) && outer.isTerminated }
        _ = await consumer.result
    }

    func test_droppingTheIterator_cancelsOuterAndInnerSequences() async throws {
        let outer = ControlledStream<Int>()
        let inners = Inners()
        let sequence = outer.stream.flatMapLatest { inners.make($0) }

        let consumer = Task {
            for try await _ in sequence {
                break
            }
        }

        outer.yield(1)
        try await inners.continuation(1).yield("a")
        try await consumer.value

        await waitUntil { inners.isTerminated(1) && outer.isTerminated }
    }

    func test_rapidSwitching_deliversOnlyIncreasingValuesAndTheLatestInner() async throws {
        let count = 500
        let outer = AsyncStream<Int> { continuation in
            for element in 0 ..< count {
                continuation.yield(element)
            }
            continuation.finish()
        }
        let sequence = outer.flatMapLatest { element in
            AsyncStream<Int> { continuation in
                continuation.yield(element)
                // Stays open like a database observation.
            }
        }
        let finished = expectation(description: "Receives the latest inner value")
        let consumer = Task {
            var values: [Int] = []
            for try await value in sequence {
                values.append(value)
                if value == count - 1 {
                    finished.fulfill()
                    return values
                }
            }
            return values
        }

        await fulfillment(of: [finished], timeout: 10)
        let values = try await consumer.value
        XCTAssertEqual(values, values.sorted())
        XCTAssertEqual(Set(values).count, values.count)
        XCTAssertEqual(values.last, count - 1)
    }

    func test_rapidSwitching_finishesRepeatedlyWithTheLatestInnerValues() async throws {
        let finished = expectation(description: "Every stream finishes")
        let runs = Task {
            for _ in 0 ..< 200 {
                let outer = AsyncStream<Int> { continuation in
                    for element in 0 ..< 10 {
                        continuation.yield(element)
                    }
                    continuation.finish()
                }
                var values: [Int] = []
                let sequence = outer.flatMapLatest { element in
                    AsyncStream<Int> { continuation in
                        continuation.yield(element * 10)
                        continuation.yield(element * 10 + 1)
                        continuation.finish()
                    }
                }
                for try await value in sequence {
                    values.append(value)
                }
                XCTAssertEqual(values, values.sorted())
                XCTAssertEqual(values.suffix(2), [90, 91])
            }
            finished.fulfill()
        }

        await fulfillment(of: [finished], timeout: 30)
        try await runs.value
    }

    // MARK: Private

    private func waitUntil(
        timeout: TimeInterval = 5,
        _ condition: () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Condition was not met in time", file: file, line: line)
                return
            }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    private func assertThrows(
        _ expected: TestError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? TestError, expected, file: file, line: line)
        }
    }
}

// MARK: - Test sequences

private enum TestError: Error {
    case expected
}

private final class ControlledStream<Element>: @unchecked Sendable {
    // MARK: Lifecycle

    init() {
        var continuation: AsyncStream<Element>.Continuation!
        stream = AsyncStream { continuation = $0 }
        self.continuation = continuation
        continuation.onTermination = { [terminated] _ in
            terminated.withCriticalRegion { $0 = true }
        }
    }

    // MARK: Internal

    let stream: AsyncStream<Element>

    var isTerminated: Bool {
        terminated.withCriticalRegion { $0 }
    }

    func yield(_ element: Element) {
        continuation.yield(element)
    }

    func finish() {
        continuation.finish()
    }

    // MARK: Private

    private let continuation: AsyncStream<Element>.Continuation
    private let terminated = ManagedCriticalState(false)
}

private struct ControlledThrowingStream<Element> {
    // MARK: Lifecycle

    init() {
        var continuation: AsyncThrowingStream<Element, Error>.Continuation!
        stream = AsyncThrowingStream { continuation = $0 }
        self.continuation = continuation
    }

    // MARK: Internal

    let stream: AsyncThrowingStream<Element, Error>
    let continuation: AsyncThrowingStream<Element, Error>.Continuation
}

/// Inner streams keyed by the outer element, created when `flatMapLatest` transforms that element.
private final class Inners: @unchecked Sendable {
    /// Counts `next()` calls so a test knows when a value was handed to `flatMapLatest`.
    struct Inner: AsyncSequence {
        typealias Element = String

        struct AsyncIterator: AsyncIteratorProtocol {
            var iterator: AsyncThrowingStream<String, Error>.AsyncIterator
            let key: Int
            let entries: ManagedCriticalState<[Int: Entry]>

            mutating func next() async throws -> String? {
                entries.withCriticalRegion { $0[key]?.pulls += 1 }
                return try await iterator.next()
            }
        }

        let stream: AsyncThrowingStream<String, Error>
        let key: Int
        let entries: ManagedCriticalState<[Int: Entry]>

        func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(iterator: stream.makeAsyncIterator(), key: key, entries: entries)
        }
    }

    struct Entry {
        let continuation: AsyncThrowingStream<String, Error>.Continuation
        var isTerminated = false
        var pulls = 0
    }

    // MARK: Internal

    func make(_ key: Int) -> Inner {
        let stream = AsyncThrowingStream<String, Error> { continuation in
            entries.withCriticalRegion { $0[key] = Entry(continuation: continuation) }
            continuation.onTermination = { [entries] _ in
                entries.withCriticalRegion { $0[key]?.isTerminated = true }
            }
        }
        return Inner(stream: stream, key: key, entries: entries)
    }

    func isTerminated(_ key: Int) -> Bool {
        entries.withCriticalRegion { $0[key]?.isTerminated ?? false }
    }

    func pulls(_ key: Int) -> Int {
        entries.withCriticalRegion { $0[key]?.pulls ?? 0 }
    }

    /// Waits until the inner stream for `key` is created.
    func continuation(_ key: Int) async throws -> AsyncThrowingStream<String, Error>.Continuation {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if let continuation = entries.withCriticalRegion({ $0[key]?.continuation }) {
                return continuation
            }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        throw InnerNotCreatedError(key: key)
    }

    // MARK: Private

    private struct InnerNotCreatedError: Error {
        let key: Int
    }

    private let entries = ManagedCriticalState<[Int: Entry]>([:])
}

/// Returns a value only after its gate opens, even when its task was cancelled meanwhile.
private final class StubbornSequence: AsyncSequence, @unchecked Sendable {
    typealias Element = String

    struct AsyncIterator: AsyncIteratorProtocol {
        let sequence: StubbornSequence

        func next() async -> String? {
            sequence.state.withCriticalRegion { $0.isWaiting = true }
            await sequence.gate.wait()
            sequence.state.withCriticalRegion { $0.didReturnStaleValue = true }
            return "stale"
        }
    }

    private struct State {
        var isWaiting = false
        var didReturnStaleValue = false
    }

    // MARK: Internal

    let gate = Gate()

    var isWaiting: Bool {
        state.withCriticalRegion { $0.isWaiting }
    }

    var didReturnStaleValue: Bool {
        state.withCriticalRegion { $0.didReturnStaleValue }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(sequence: self)
    }

    // MARK: Private

    private let state = ManagedCriticalState(State())
}

private actor Gate {
    // MARK: Internal

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }

    // MARK: Private

    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
}
