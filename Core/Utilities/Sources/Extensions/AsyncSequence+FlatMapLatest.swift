//
//  AsyncSequence+FlatMapLatest.swift
//

// Mirrors `flatMapLatest` from swift-async-algorithms, which needs iOS 18 and isn't in the version this repo pins.
public extension AsyncSequence {
    /// Iterates the sequence returned by `transform` for the latest element, cancelling the previous one.
    ///
    /// Values from a superseded inner sequence are never delivered. An error from this sequence or the current inner
    /// sequence finishes the stream. The stream finishes after this sequence and the latest inner sequence finish.
    func flatMapLatest<Inner: AsyncSequence>(
        _ transform: @escaping @Sendable (Element) -> Inner
    ) -> AnyAsyncSequence<Inner.Element> {
        AnyAsyncSequence(FlatMapLatestSequence(base: self, transform: transform))
    }
}

private struct FlatMapLatestSequence<Base: AsyncSequence, Inner: AsyncSequence>: AsyncSequence {
    typealias Element = Inner.Element

    struct AsyncIterator: AsyncIteratorProtocol {
        // MARK: Internal

        mutating func next() async throws -> Element? {
            while let value = try await iterator.next() {
                // Drops values buffered before their inner sequence was superseded.
                if state.isCurrent(value.generation) {
                    return value.element
                }
            }
            return nil
        }

        // MARK: Fileprivate

        fileprivate var iterator: AsyncThrowingStream<GenerationValue, Error>.AsyncIterator
        fileprivate let state: FlatMapLatestState
    }

    // MARK: Internal

    let base: Base
    let transform: @Sendable (Base.Element) -> Inner

    func makeAsyncIterator() -> AsyncIterator {
        let state = FlatMapLatestState()
        let stream = AsyncThrowingStream<GenerationValue, Error> { continuation in
            continuation.onTermination = { @Sendable _ in
                state.terminate()
            }
            state.start(Task {
                await iterateBase(state: state, continuation: continuation)
            })
        }
        return AsyncIterator(iterator: stream.makeAsyncIterator(), state: state)
    }

    // MARK: Fileprivate

    fileprivate typealias Continuation = AsyncThrowingStream<GenerationValue, Error>.Continuation

    fileprivate struct GenerationValue {
        let generation: Int
        let element: Element
    }

    // MARK: Private

    private func iterateBase(state: FlatMapLatestState, continuation: Continuation) async {
        do {
            for try await element in base {
                let inner = transform(element)
                state.switchInner { generation in
                    Task {
                        await iterateInner(inner, generation: generation, state: state, continuation: continuation)
                    }
                }
            }
            if state.finishBase() {
                continuation.finish()
            }
        } catch {
            if state.fail(generation: nil) {
                continuation.finish(throwing: error)
            }
        }
    }

    private func iterateInner(
        _ inner: Inner,
        generation: Int,
        state: FlatMapLatestState,
        continuation: Continuation
    ) async {
        do {
            for try await element in inner {
                let isCurrent = state.ifCurrent(generation) {
                    continuation.yield(GenerationValue(generation: generation, element: element))
                }
                guard isCurrent else { return }
            }
            if state.finishInner(generation: generation) {
                continuation.finish()
            }
        } catch {
            if state.fail(generation: generation) {
                continuation.finish(throwing: error)
            }
        }
    }
}

/// Tracks the current inner generation and the running tasks.
///
/// `continuation.finish` and `Task.cancel` are called outside the lock because they run termination and
/// cancellation handlers synchronously, and the stream's termination handler takes this lock.
private final class FlatMapLatestState: Sendable {
    private struct State: Sendable {
        var generation = 0
        var baseTask: Task<Void, Never>?
        var innerTask: Task<Void, Never>?
        var isBaseFinished = false
        var isInnerFinished = true
        var isTerminated = false

        /// Returns the tasks to cancel outside the lock.
        mutating func terminate() -> [Task<Void, Never>] {
            isTerminated = true
            defer {
                baseTask = nil
                innerTask = nil
            }
            return [baseTask, innerTask].compactMap { $0 }
        }
    }

    // MARK: Internal

    func start(_ baseTask: Task<Void, Never>) {
        let isTerminated = state.withCriticalRegion { state in
            guard !state.isTerminated else { return true }
            state.baseTask = baseTask
            return false
        }
        if isTerminated {
            baseTask.cancel()
        }
    }

    /// Starts the inner task for a new generation and cancels the previous one.
    func switchInner(_ makeTask: (Int) -> Task<Void, Never>) {
        let previousTask = state.withCriticalRegion { state -> Task<Void, Never>? in
            guard !state.isTerminated else { return nil }
            let previousTask = state.innerTask
            state.generation += 1
            state.isInnerFinished = false
            state.innerTask = makeTask(state.generation)
            return previousTask
        }
        previousTask?.cancel()
    }

    func isCurrent(_ generation: Int) -> Bool {
        state.withCriticalRegion { $0.generation == generation }
    }

    /// Runs `body` while holding the lock when `generation` is current, so a switch can't interleave with a yield.
    func ifCurrent(_ generation: Int, _ body: () -> Void) -> Bool {
        state.withCriticalRegion { state in
            guard !state.isTerminated, state.generation == generation else { return false }
            body()
            return true
        }
    }

    /// Returns whether the stream should finish now.
    func finishBase() -> Bool {
        state.withCriticalRegion { state in
            state.isBaseFinished = true
            return !state.isTerminated && state.isInnerFinished
        }
    }

    /// Returns whether the stream should finish now.
    func finishInner(generation: Int) -> Bool {
        state.withCriticalRegion { state in
            guard !state.isTerminated, state.generation == generation else { return false }
            state.isInnerFinished = true
            return state.isBaseFinished
        }
    }

    /// Marks the stream terminated when the failure comes from the base (`nil`) or the current inner sequence.
    /// Returns whether the caller should finish the stream with its error.
    func fail(generation: Int?) -> Bool {
        let tasks = state.withCriticalRegion { state -> [Task<Void, Never>]? in
            guard !state.isTerminated else { return nil }
            if let generation, generation != state.generation {
                return nil
            }
            return state.terminate()
        }
        guard let tasks else { return false }
        tasks.forEach { $0.cancel() }
        return true
    }

    func terminate() {
        let tasks = state.withCriticalRegion { $0.terminate() }
        tasks.forEach { $0.cancel() }
    }

    // MARK: Private

    private let state = ManagedCriticalState(State())
}
