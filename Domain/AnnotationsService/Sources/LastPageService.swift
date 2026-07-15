//
//  LastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import QuranAnnotations
import QuranKit

public struct LastPagesSequence: AsyncSequence {
    public typealias Element = [LastPage]

    public struct AsyncIterator: AsyncIteratorProtocol {
        init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
            var iterator = sequence.makeAsyncIterator()
            nextValue = {
                try await iterator.next()
            }
        }

        public mutating func next() async throws -> Element? {
            try await nextValue()
        }

        private let nextValue: () async throws -> Element?
    }

    public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        makeIterator = {
            AsyncIterator(sequence)
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        makeIterator()
    }

    private let makeIterator: () -> AsyncIterator
}

@MainActor
public protocol LastPageService {
    func lastPages(quran: Quran) -> LastPagesSequence

    func add(page: Page) async throws -> LastPage

    func update(lastPage: LastPage, toPage: Page) async throws -> LastPage
}
