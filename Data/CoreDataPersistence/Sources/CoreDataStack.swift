//
//  CoreDataStack.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import Crashing
import Foundation
import Utilities
import VLogging

/// A loaded Core Data store, including history processing.
///
/// Creating a stack loads its store, so a stack always has an open store and never changes
/// afterward. Nothing can read the store before it opens, and any thread can use the stack
/// without a lock.
public final class CoreDataStack: @unchecked Sendable {
    // MARK: Lifecycle

    /// Loads the store, migrating it if needed.
    ///
    /// A load failure, such as the device being out of storage, is thrown; create another stack
    /// to try again. Use ``PersistentStoreFailure/isStorageFull(_:)`` to classify it.
    public convenience init(name: String, modelUrl: URL, lazyUniquifiers: @escaping () -> [CoreDataEntityUniquifier]) throws {
        try self.init(
            name: name,
            modelUrl: modelUrl,
            lazyUniquifiers: lazyUniquifiers,
            persistentStoreLoader: Self.loadPersistentStores
        )
    }

    init(
        name: String,
        modelUrl: URL,
        lazyUniquifiers: @escaping () -> [CoreDataEntityUniquifier],
        persistentStoreLoader: @escaping (NSPersistentContainer) -> NSError?
    ) throws {
        self.name = name
        self.lazyUniquifiers = lazyUniquifiers
        persistentContainer = try Self.makeLoadedPersistentContainer(
            name: name,
            modelUrl: modelUrl,
            persistentStoreLoader: persistentStoreLoader
        )

        // Observe Core Data remote change notifications.
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange, object: persistentContainer.persistentStoreCoordinator
        )
    }

    // MARK: Public

    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    public class func removePersistentFiles() {
        let dataDirectory = NSPersistentContainer.defaultDirectoryURL()
        FileManager.default.removeDirectoryContents(at: dataDirectory)
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.transactionAuthor = Self.appTransactionAuthorName
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Emits whenever the store changes, including CloudKit imports, after history processing merges the change.
    ///
    /// The subscription is active when this method returns.
    public func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        changeContinuations.withCriticalRegion { $0[id] = continuation }
        continuation.onTermination = { [changeContinuations] _ in
            changeContinuations.withCriticalRegion { $0[id] = nil }
        }
        return stream
    }

    // MARK: Internal

    /// A persistent container that can load cloud-backed and non-cloud stores.
    let persistentContainer: NSPersistentContainer

    static func configurePersistentStores(in container: NSPersistentContainer, name: String) {
        let descriptions = container.persistentStoreDescriptions
        guard !descriptions.isEmpty else {
            crashContext.setPersistence(store: name, operation: "load_store", phase: "missing_description")
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        for description in descriptions {
            description.shouldAddStoreAsynchronously = false
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
    }

    // MARK: Private

    private static let appTransactionAuthorName = "app"

    private let name: String

    /// Separate from history processing, so subscribing never waits for a merge.
    private let changeContinuations = ManagedCriticalState<[UUID: AsyncStream<Void>.Continuation]>([:])

    private let lazyUniquifiers: () -> [CoreDataEntityUniquifier]

    // Only read on `historyQueue`, which runs one operation at a time.
    private lazy var uniquifiers: [CoreDataEntityUniquifier] = lazyUniquifiers()
    private lazy var historyProcessor: CoreDataPersistentHistoryProcessor = .init(name: name, uniquifiers: uniquifiers)

    /// An operation queue for handling history processing tasks: watching changes, deduplicating entities, and triggering UI updates if needed.
    private let historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private static func newPersistenceContainer(name: String, modelUrl: URL) -> NSPersistentContainer {
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Cannot find \(modelUrl)")
        }

        // Create a container that can load CloudKit-backed stores
        return NSPersistentCloudKitContainer(name: name, managedObjectModel: model)
    }

    private static func makeLoadedPersistentContainer(
        name: String,
        modelUrl: URL,
        persistentStoreLoader: (NSPersistentContainer) -> NSError?
    ) throws -> NSPersistentContainer {
        crashContext.setPersistence(store: name, operation: "load_store", phase: "starting")
        logger.info("Core Data store load starting: \(name)")
        let container = try loadPersistentContainer(name: name, modelUrl: modelUrl, persistentStoreLoader: persistentStoreLoader)
        crashContext.setPersistence(store: name, operation: "load_store", phase: "ready")
        logger.info("Core Data store loaded: \(name)")

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = appTransactionAuthorName

        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            crashContext.setPersistence(store: name, operation: "pin_generation", phase: "failed")
            logger.error("Core Data failed to pin the view context generation: \(name). Error: \(error)")
            // Close the discarded stores, so a retry never opens the file with a second coordinator.
            let coordinator = container.persistentStoreCoordinator
            for store in coordinator.persistentStores {
                try? coordinator.remove(store)
            }
            throw error
        }

        return container
    }

    private static func loadPersistentContainer(
        name: String,
        modelUrl: URL,
        persistentStoreLoader: (NSPersistentContainer) -> NSError?
    ) throws -> NSPersistentContainer {
        var attempt = 1
        while true {
            let container = newPersistenceContainer(name: name, modelUrl: modelUrl)
            configurePersistentStores(in: container, name: name)

            guard let error = persistentStoreLoader(container) else {
                return container
            }
            guard PersistentStoreLoadRecovery.shouldRetry(error, attempt: attempt) else {
                crashContext.setPersistence(store: name, operation: "load_store", phase: "failed")
                logger.error("Core Data store failed to load: \(name). Error: \(error)")
                throw error
            }

            crashContext.setPersistence(store: name, operation: "load_store", phase: "retrying_sqlite_misuse")
            crasher.recordError(error, reason: "Retrying Core Data store after SQLite misuse during initialization")
            logger.error("Core Data store returned SQLite misuse during initialization; retrying with a fresh container.")
            attempt += 1
        }
    }

    private static func loadPersistentStores(in container: NSPersistentContainer) -> NSError? {
        // The completion is escaping because Core Data also supports asynchronous
        // descriptions. Capturing its result here is valid only while every store
        // is explicitly configured to finish loading before this method returns.
        precondition(
            !container.persistentStoreDescriptions.isEmpty &&
                container.persistentStoreDescriptions.allSatisfy { !$0.shouldAddStoreAsynchronously },
            "Persistent stores must be configured for synchronous loading."
        )

        var loadError: NSError?
        container.loadPersistentStores { _, error in
            if loadError == nil {
                loadError = error as NSError?
            }
        }
        return loadError
    }

    /// Handle remote store change notifications (.NSPersistentStoreRemoteChange).
    @objc
    private func storeRemoteChange(_ notification: Notification) {
        crashContext.setPersistence(store: name, operation: "merge_remote_change", phase: "queued")
        logger.info("Merging changes from the other persistent store coordinator.")

        // Process persistent history to merge changes from other coordinators.
        historyQueue.addOperation {
            let taskContext = self.newBackgroundContext()
            taskContext.performAndWait {
                crashContext.setPersistence(store: self.name, operation: "merge_remote_change", phase: "executing")
                self.historyProcessor.processNewHistory(using: taskContext)
                crashContext.setPersistence(store: self.name, operation: "merge_remote_change", phase: "ready")
            }
            // Emitted after history processing, so observers read deduplicated data.
            let continuations = self.changeContinuations.withCriticalRegion { Array($0.values) }
            for continuation in continuations {
                continuation.yield()
            }
        }
    }
}

enum PersistentStoreLoadRecovery {
    static func shouldRetry(_ error: NSError, attempt: Int) -> Bool {
        attempt == 1 && error.domain == "NSSQLiteErrorDomain" && error.code == 21
    }
}
