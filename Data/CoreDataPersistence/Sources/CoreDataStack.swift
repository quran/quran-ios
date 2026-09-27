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

/// Core Data stack setup including history processing.
public class CoreDataStack {
    // MARK: Lifecycle

    public convenience init(name: String, modelUrl: URL, lazyUniquifiers: @escaping () -> [CoreDataEntityUniquifier]) {
        self.init(
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
    ) {
        self.name = name
        self.modelUrl = modelUrl
        self.lazyUniquifiers = lazyUniquifiers
        self.persistentStoreLoader = persistentStoreLoader
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
        makeBackgroundContext(in: persistentContainer)
    }

    /// Loads the store if needed and creates a background context.
    ///
    /// Unlike ``newBackgroundContext()``, a load failure, such as protected data being
    /// unavailable, is thrown instead of crashing, and the next call tries to load again.
    public func openBackgroundContext() throws -> NSManagedObjectContext {
        try makeBackgroundContext(in: loadedPersistentContainer())
    }

    /// Emits whenever the store changes, including CloudKit imports, after history processing merges the change.
    ///
    /// The subscription is active when this method returns, even before the store loads.
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
    var persistentContainer: NSPersistentContainer {
        do {
            return try loadedPersistentContainer()
        } catch {
            fatalError("###\(#function): Failed to load persistent store: \(error)")
        }
    }

    // MARK: Private

    private let appTransactionAuthorName = "app"

    private let name: String
    private let modelUrl: URL
    private let persistentStoreLoader: (NSPersistentContainer) -> NSError?

    private let containerLock = NSLock()
    private var loadedContainer: NSPersistentContainer?

    /// Separate from the container lock, so subscribing never waits for a store load.
    private let changeContinuations = ManagedCriticalState<[UUID: AsyncStream<Void>.Continuation]>([:])

    private let lazyUniquifiers: () -> [CoreDataEntityUniquifier]
    private lazy var uniquifiers: [CoreDataEntityUniquifier] = lazyUniquifiers()

    private lazy var historyProcessor: CoreDataPersistentHistoryProcessor = .init(name: name, uniquifiers: uniquifiers)

    /// An operation queue for handling history processing tasks: watching changes, deduplicating entities, and triggering UI updates if needed.
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private func newPersistenceContainer() -> NSPersistentContainer {
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Cannot find \(modelUrl)")
        }

        // Create a container that can load CloudKit-backed stores
        return NSPersistentCloudKitContainer(name: name, managedObjectModel: model)
    }

    /// Returns the loaded container, loading it on first use. A failed load is not cached.
    private func loadedPersistentContainer() throws -> NSPersistentContainer {
        containerLock.lock()
        defer { containerLock.unlock() }
        if let loadedContainer {
            return loadedContainer
        }
        let container = try makeLoadedPersistentContainer()
        loadedContainer = container
        return container
    }

    private func makeLoadedPersistentContainer() throws -> NSPersistentContainer {
        crashContext.setPersistence(store: name, operation: "load_store", phase: "starting")
        logger.info("Core Data store load starting: \(name)")
        let container = try loadPersistentContainer()
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

        // Observe Core Data remote change notifications.
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange, object: container.persistentStoreCoordinator
        )

        return container
    }

    private func makeBackgroundContext(in container: NSPersistentContainer) -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.transactionAuthor = appTransactionAuthorName
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    private func loadPersistentContainer() throws -> NSPersistentContainer {
        var attempt = 1
        while true {
            let container = newPersistenceContainer()
            configurePersistentStores(in: container)

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

    func configurePersistentStores(in container: NSPersistentContainer) {
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
