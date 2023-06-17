//
//  AsyncThrowingPublisher.swift
//
//
//  Created by Mohamed Afifi on 2023-06-11.
//

import Combine

// Inspired by: https://github.com/groue/GRDB.swift/blob/0a92a99223c30dc959d4fee13e2806ff4f242473/GRDB/ValueObservation/ValueObservation.swift#L335

public struct AsyncThrowingPublisher<Element>: AsyncSequence {
    public typealias BufferingPolicy = AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy
    public typealias AsyncIterator = Iterator

    public struct Iterator: AsyncIteratorProtocol {
        // MARK: Public

        public mutating func next() async throws -> Element? {
            try await iterator.next()
        }

        // MARK: Internal

        var iterator: AsyncThrowingStream<Element, Error>.AsyncIterator
        let cancellable: AnyCancellable
    }

    // MARK: Public

    public func makeAsyncIterator() -> Iterator {
        // This cancellable will be retained by the Iterator, which itself will
        // be retained by the Swift async runtime.
        //
        // We must not retain this cancellable in any other way, in order to
        // cancel the observation when the Swift async runtime releases
        // the iterator.
        var cancellable: AnyCancellable?
        let stream = AsyncThrowingStream(Element.self, bufferingPolicy: bufferingPolicy) { continuation in

            cancellable = publisher.sink { completion in
                switch completion {
                case .finished:
                    continuation.finish()
                case .failure(let error):
                    continuation.finish(throwing: error)
                }

            } receiveValue: { [weak cancellable] value in
                if case .terminated = continuation.yield(value) {
                    // TODO: I could never see this code running. Is it needed?
                    cancellable?.cancel()
                }
            }

            continuation.onTermination = { @Sendable [weak cancellable] _ in
                cancellable?.cancel()
            }
        }

        let iterator = stream.makeAsyncIterator()
        if let cancellable {
            return Iterator(
                iterator: iterator,
                cancellable: cancellable
            )
        } else {
            // Bug: there is no point throwing any error.
            fatalError("Expected AsyncThrowingStream to have started the observation already")
        }
    }

    // MARK: Internal

    var bufferingPolicy: BufferingPolicy
    var publisher: AnyPublisher<Element, Error>
}

public extension Publisher {
    func values(
        bufferingPolicy: AsyncThrowingPublisher<Output>.BufferingPolicy = .unbounded)
        -> AsyncThrowingPublisher<Output>
    {
        AsyncThrowingPublisher(
            bufferingPolicy: bufferingPolicy,
            publisher: mapError { $0 }.eraseToAnyPublisher()
        )
    }
}
