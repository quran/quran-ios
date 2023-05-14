//
//  OpaqueAsyncSequence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-01.
//

import AsyncExtensions

public extension AsyncSequence {
    /// Type erase the AsyncSequence into an OpaqueAsyncSequence.
    /// - Returns: A type erased AsyncSequence.
    func eraseToOpaqueAsyncSequence() -> OpaqueAsyncSequence<Self> where Self: Sendable {
        OpaqueAsyncSequence(self)
    }
}

/// Type erased version of an AsyncSequence.
public struct OpaqueAsyncSequence<Base: AsyncSequence>: AsyncSequence, Sendable where Base: Sendable {
    public typealias Element = Base.Element
    public typealias AsyncIterator = Iterator<Base.AsyncIterator>

    private let base: Base
    public init(_ base: Base) {
        self.base = base
    }

    public func makeAsyncIterator() -> AsyncIterator {
        Iterator(base: base.makeAsyncIterator())
    }

    public struct Iterator<Base: AsyncIteratorProtocol>: AsyncIteratorProtocol {
        public typealias Element = Base.Element
        private var base: Base
        public init(base: Base) {
            self.base = base
        }

        public mutating func next() async rethrows -> Element? {
            try await base.next()
        }
    }
}
