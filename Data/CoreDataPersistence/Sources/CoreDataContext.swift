//
//  CoreDataContext.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import Combine
import CoreData
import Crashing
import Foundation
import Utilities
import VLogging

/// A background context whose store opens on first use.
///
/// Every operation waits for ``CoreDataStore`` to open the store, so a store that can't open
/// throws like any other query error.
public final class CoreDataContext: @unchecked Sendable {
    // MARK: Lifecycle

    public init(store: CoreDataStore) {
        self.store = store
    }

    // MARK: Public

    public func perform<T>(_ operation: @Sendable @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await context().perform(operation)
    }

    /// Emits the request's results whenever they change. Emits nothing if the store can't open.
    public func publisher<Result: NSFetchRequestResult>(for request: NSFetchRequest<Result>) -> AnyPublisher<[Result], Never> {
        Deferred {
            if let context = self.openedContext() {
                return Just(context).eraseToAnyPublisher()
            }
            let opened = CurrentValueSubject<NSManagedObjectContext?, Never>(nil)
            Task {
                do {
                    try await opened.send(self.context())
                } catch {
                    logger.error("Core Data publisher couldn't open its store. Error: \(error)")
                    crasher.recordError(error, reason: "A Core Data publisher couldn't open its store")
                }
            }
            return opened.compactMap { $0 }.first().eraseToAnyPublisher()
        }
        .flatMap { context in
            CoreDataPublisher(request: request, context: context)
        }
        .eraseToAnyPublisher()
    }

    // MARK: Private

    private let store: CoreDataStore
    private let cachedContext = ManagedCriticalState<NSManagedObjectContext?>(nil)

    private func context() async throws -> NSManagedObjectContext {
        if let context = openedContext() {
            return context
        }
        return keep(try await store.stack().newBackgroundContext())
    }

    /// The context, if the store is already open.
    private func openedContext() -> NSManagedObjectContext? {
        if let context = cachedContext.withCriticalRegion({ $0 }) {
            return context
        }
        return store.loadedStack().map { keep($0.newBackgroundContext()) }
    }

    /// Keeps the first context created, so every operation uses one context and stays ordered.
    private func keep(_ context: NSManagedObjectContext) -> NSManagedObjectContext {
        cachedContext.withCriticalRegion { cached in
            if let cached {
                return cached
            }
            cached = context
            return context
        }
    }
}
