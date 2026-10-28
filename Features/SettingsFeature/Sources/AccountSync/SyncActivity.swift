#if QURAN_SYNC
//
//  SyncActivity.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation
import MobileSync
import VLogging

/// What MobileSync says about syncing: the live status, the recent runs and the items that don't sync.
struct SyncActivity: Equatable {
    enum State: Equatable {
        case syncing
        /// The latest sync failed. `error` is `nil` when it only couldn't send the local changes.
        case failed(MobileSyncRunError?)
        case synced(at: Date)
        case neverSynced
    }

    enum Change {
        case status(MobileSyncStatus)
        case runs([MobileSyncRun])
        case heldItems([MobileSyncHeldItem])
    }

    // MARK: Internal

    var status: MobileSyncStatus = .idle
    /// The newest first.
    var runs: [MobileSyncRun] = []
    var heldItems: [MobileSyncHeldItem] = []

    /// The status resets to idle at launch, so the stored runs fill in what it doesn't know.
    var state: State {
        if status == .syncing {
            return .syncing
        }
        let latestRun = runs.first { $0.result != .cancelled }
        if case .failed(let failedAt, let error) = status, latestRun.map({ $0.endedAt <= failedAt }) ?? true {
            return .failed(error)
        }
        switch latestRun?.result {
        case .failed:
            return .failed(latestRun?.error)
        case .pulledOnly:
            // Pushes stay paused after a failure until a sync that sends the changes succeeds.
            return .failed(runs.first { $0.result == .failed }?.error)
        default:
            break
        }
        if let lastSynced {
            return .synced(at: lastSynced)
        }
        return .neverSynced
    }

    /// When a sync last succeeded.
    var lastSynced: Date? {
        let lastRun = runs.first { $0.result == .succeeded }?.endedAt
        guard case .succeeded(let at) = status else {
            return lastRun
        }
        return max(at, lastRun ?? at)
    }

    /// The held items the user can fix: the ones that don't just wait on another held item.
    var blockingItems: [MobileSyncHeldItem] {
        heldItems.filter { $0.waitingOn == nil }
    }

    /// Follows MobileSync's status, runs and held items until the task iterating it is cancelled.
    static func changes(of service: MobileSyncDataService) -> AsyncStream<Change> {
        AsyncStream { continuation in
            let tasks = [
                forward(service.syncStatusSequence(), to: continuation, as: Change.status),
                forward(service.syncHistorySequence(), to: continuation, as: Change.runs),
                forward(service.heldItemsSequence(), to: continuation, as: Change.heldItems),
            ]
            continuation.onTermination = { _ in
                // Cancelling, not breaking out, stops MobileSync's collectors.
                tasks.forEach { $0.cancel() }
            }
        }
    }

    mutating func apply(_ change: Change) {
        switch change {
        case .status(let status): self.status = status
        case .runs(let runs): self.runs = runs
        case .heldItems(let heldItems): self.heldItems = heldItems
        }
    }
}

/// Yields each value of `sequence` to `continuation` until cancelled. A failure stops only this sequence.
func forward<Element, Value>(
    _ sequence: MobileSyncAsyncSequence<Element>,
    to continuation: AsyncStream<Value>.Continuation,
    as transform: @escaping @Sendable (Element) -> Value
) -> Task<Void, Never> {
    Task {
        do {
            for try await element in sequence {
                continuation.yield(transform(element))
            }
        } catch is CancellationError {
            return
        } catch {
            logger.error("Quran Sync: stopped observing sync activity: \(error)")
        }
    }
}
#endif
