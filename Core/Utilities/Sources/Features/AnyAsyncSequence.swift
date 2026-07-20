//
//  AnyAsyncSequence.swift
//

public struct AnyAsyncSequence<Element>: AsyncSequence {
    public struct AsyncIterator: AsyncIteratorProtocol {
        fileprivate init<I: AsyncIteratorProtocol>(
            _ iterator: I
        ) where I.Element == Element {
            var iterator = iterator

            nextValue = {
                try await iterator.next()
            }
        }

        public mutating func next() async throws -> Element? {
            try await nextValue()
        }

        private let nextValue: () async throws -> Element?
    }

    public init<S: AsyncSequence>(
        _ sequence: S
    ) where S.Element == Element {
        makeIterator = {
            AsyncIterator(sequence.makeAsyncIterator())
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        makeIterator()
    }

    private let makeIterator: () -> AsyncIterator
}
