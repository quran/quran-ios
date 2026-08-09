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
        let context = persistentContainer.newBackgroundContext()
        context.transactionAuthor = appTransactionAuthorName
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: Internal

    /// A persistent container that can load cloud-backed and non-cloud stores.
    lazy var persistentContainer: NSPersistentContainer = {
        crashContext.setPersistence(store: name, operation: "load_store", phase: "starting")
        logger.info("Core Data store load starting: \(name)")
        let container = loadPersistentContainer()
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
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
        }

        // Observe Core Data remote change notifications.
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange, object: container.persistentStoreCoordinator
        )

        return container
    }()

    // MARK: Private

    private let appTransactionAuthorName = "app"

    private let name: String
    private let modelUrl: URL
    private let persistentStoreLoader: (NSPersistentContainer) -> NSError?

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

    private func loadPersistentContainer() -> NSPersistentContainer {
        var attempt = 1
        while true {
            let container = newPersistenceContainer()
            configurePersistentStore(in: container)

            guard let error = persistentStoreLoader(container) else {
                return container
            }
            guard PersistentStoreLoadRecovery.shouldRetry(error, attempt: attempt) else {
                crashContext.setPersistence(store: name, operation: "load_store", phase: "failed")
                fatalError("###\(#function): Failed to load persistent store: \(error)")
            }

            crashContext.setPersistence(store: name, operation: "load_store", phase: "retrying_sqlite_misuse")
            crasher.recordError(error, reason: "Retrying Core Data store after SQLite misuse during initialization")
            logger.error("Core Data store returned SQLite misuse during initialization; retrying with a fresh container.")
            attempt += 1
        }
    }

    private func configurePersistentStore(in container: NSPersistentContainer) {
        guard let description = container.persistentStoreDescriptions.first else {
            crashContext.setPersistence(store: name, operation: "load_store", phase: "missing_description")
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        description.shouldAddStoreAsynchronously = false
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    private static func loadPersistentStores(in container: NSPersistentContainer) -> NSError? {
        var loadError: NSError?
        container.loadPersistentStores { _, error in
            loadError = error as NSError?
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
        }
    }
}

enum PersistentStoreLoadRecovery {
    static func shouldRetry(_ error: NSError, attempt: Int) -> Bool {
        attempt == 1 && error.domain == "NSSQLiteErrorDomain" && error.code == 21
    }
}
