//
//  CoreDataStore.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import CoreData
import Foundation
import Utilities

/// Opens the Core Data store once and hands out the loaded stack.
///
/// The first call to ``stack()`` loads the store, migrating it if needed, off the main thread.
/// Calls made meanwhile wait for that load. A failed load isn't kept, so the next call tries again.
public actor CoreDataStore {
    // MARK: Lifecycle

    public init(name: String, modelUrl: URL, lazyUniquifiers: @escaping @Sendable () -> [CoreDataEntityUniquifier]) {
        self.init(
            name: name,
            modelUrl: modelUrl,
            lazyUniquifiers: lazyUniquifiers,
            persistentStoreLoader: { CoreDataStack.loadPersistentStores(in: $0) }
        )
    }

    init(
        name: String,
        modelUrl: URL,
        lazyUniquifiers: @escaping @Sendable () -> [CoreDataEntityUniquifier],
        persistentStoreLoader: @escaping @Sendable (NSPersistentContainer) -> NSError?
    ) {
        self.name = name
        self.modelUrl = modelUrl
        self.lazyUniquifiers = lazyUniquifiers
        self.persistentStoreLoader = persistentStoreLoader
    }

    // MARK: Public

    /// The loaded stack. Throws when the store can't load, such as when the device is out of
    /// storage; use ``PersistentStoreFailure/isStorageFull(_:)`` to classify the error.
    public func stack() throws -> CoreDataStack {
        if let loadedStack = loadedStack() {
            return loadedStack
        }
        let changeContinuations = changeContinuations
        let stack = try CoreDataStack(
            name: name,
            modelUrl: modelUrl,
            lazyUniquifiers: lazyUniquifiers,
            persistentStoreLoader: persistentStoreLoader,
            onChange: {
                for continuation in changeContinuations.withCriticalRegion({ Array($0.values) }) {
                    continuation.yield()
                }
            }
        )
        openedStack.withCriticalRegion { $0 = stack }
        return stack
    }

    /// Emits whenever the store changes, including CloudKit imports, after history processing merges the change.
    ///
    /// The subscription is active when this method returns, even before the store loads.
    public nonisolated func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        changeContinuations.withCriticalRegion { $0[id] = continuation }
        continuation.onTermination = { [changeContinuations] _ in
            changeContinuations.withCriticalRegion { $0[id] = nil }
        }
        return stream
    }

    // MARK: Internal

    /// The stack if the store is open, without waiting for a load in progress.
    nonisolated func loadedStack() -> CoreDataStack? {
        openedStack.withCriticalRegion { $0 }
    }

    // MARK: Private

    private let name: String
    private let modelUrl: URL
    private let lazyUniquifiers: @Sendable () -> [CoreDataEntityUniquifier]
    private let persistentStoreLoader: @Sendable (NSPersistentContainer) -> NSError?
    private nonisolated let openedStack = ManagedCriticalState<CoreDataStack?>(nil)

    /// Outside the actor, so subscribing never waits for a store load.
    private nonisolated let changeContinuations = ManagedCriticalState<[UUID: AsyncStream<Void>.Continuation]>([:])
}
