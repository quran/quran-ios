//
//  AsyncPublisher.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import Combine

// Inspired by: https://github.com/groue/GRDB.swift/blob/0a92a99223c30dc959d4fee13e2806ff4f242473/GRDB/ValueObservation/ValueObservation.swift#L335

public struct AsyncPublisher<Element>: AsyncSequence {
    public typealias BufferingPolicy = AsyncStream<Element>.Continuation.BufferingPolicy
    public typealias AsyncIterator = Iterator

    var bufferingPolicy: BufferingPolicy
    var publisher: AnyPublisher<Element, Never>

    public func makeAsyncIterator() -> Iterator {
        // This cancellable will be retained by the Iterator, which itself will
        // be retained by the Swift async runtime.
        //
        // We must not retain this cancellable in any other way, in order to
        // cancel the observation when the Swift async runtime releases
        // the iterator.
        var cancellable: AnyCancellable?
        let stream = AsyncStream(Element.self, bufferingPolicy: bufferingPolicy) { continuation in

            cancellable = publisher.sink { completion in
                continuation.finish()
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
            fatalError("Expected AsyncStream to have started the observation already")
        }
    }

    public struct Iterator: AsyncIteratorProtocol {
        var iterator: AsyncStream<Element>.AsyncIterator
        let cancellable: AnyCancellable

        public mutating func next() async -> Element? {
            await iterator.next()
        }
    }
}

public extension Publisher where Failure == Never {
    func values(bufferingPolicy: AsyncPublisher<Output>.BufferingPolicy = .unbounded) -> AsyncPublisher<Output> {
        AsyncPublisher(bufferingPolicy: bufferingPolicy, publisher: eraseToAnyPublisher())
    }
}
