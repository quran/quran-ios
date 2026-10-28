#if QURAN_SYNC
//
//  FirstElement.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation

/// The first element of `sequence`, or `nil` when it ends first.
///
/// A MobileSync sequence keeps its collector running until the task iterating it is cancelled while it waits for
/// the next element; returning from the loop leaves it running. So a child task iterates and hands over the first
/// element, then the group cancels it. Cancelling the caller cancels the child too.
func firstElement<Sequence: AsyncSequence>(of sequence: Sequence) async throws -> Sequence.Element? {
    var continuation: AsyncStream<Sequence.Element>.Continuation?
    let elements = AsyncStream<Sequence.Element> { continuation = $0 }
    return try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { [continuation] in
            defer { continuation?.finish() }
            do {
                for try await element in sequence {
                    continuation?.yield(element)
                }
            } catch is CancellationError {}
        }
        var iterator = elements.makeAsyncIterator()
        let first = await iterator.next()
        group.cancelAll()
        // Rethrows the sequence's failure when it ended without an element.
        try await group.waitForAll()
        try Task.checkCancellation()
        return first
    }
}
#endif
