//
//  Task+Extension.swift
//
//
//  Created by Mohamed Afifi on 2023-05-02.
//

import AsyncAlgorithms
import Foundation

public final class CancellableTask {
    private let cancel: () -> Void

    init<T, E>(task: Task<T, E>) {
        cancel = { task.cancel() }
    }

    deinit {
        cancel()
    }
}

extension Task {
    public func asCancellableTask() -> CancellableTask {
        CancellableTask(task: self)
    }
}

extension AsyncChannel {
    public func next() async -> Element? {
        var iterator = makeAsyncIterator()
        return await iterator.next()
    }
}
