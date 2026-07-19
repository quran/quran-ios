//
//  AsyncChannelEventObserver.swift
//
//
//  Created by Mohamed Afifi on 2023-11-05.
//

import AsyncAlgorithms
import SystemDependencies

public struct AsyncChannelEventObserver: EventObserver {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func notify() async {
        await channel.send(())
    }

    public func waitForNextEvent() async {
        var iterator = channel.makeAsyncIterator()
        await iterator.next()
    }

    // MARK: Private

    private let channel = AsyncChannel<Void>()
}
