//
//  AsyncAlgorithms++.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import AsyncAlgorithms

extension AsyncChannel {
    public func next() async -> Element? {
        var iterator = makeAsyncIterator()
        return await iterator.next()
    }
}
