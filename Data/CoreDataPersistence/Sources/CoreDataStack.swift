//
//  CoreDataStack.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import Foundation
import Utilities
import VLogging

/// Core Data stack setup including history processing.
public class CoreDataStack {
    // MARK: Lifecycle

    public init(name: String, modelUrl: URL, lazyUniquifiers: @escaping () -> [CoreDataEntityUniquifier]) {
        self.name = name
        self.modelUrl = modelUrl
        self.lazyUniquifiers = lazyUniquifiers
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
        return context
    }

    // MARK: Internal

    /// A persistent container that can load cloud-backed and non-cloud stores.
    lazy var persistentContainer: NSPersistentContainer = {
        let container = newPersistenceContainer()

        // Enable history tracking and remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores(completionHandler: { _, error in
            guard let error = error as NSError? else { return }
            fatalError("###\(#function): Failed to load persistent store: \(error)")
        })

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = appTransactionAuthorName

        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
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

    private let lazyUniquifiers: () -> [CoreDataEntityUniquifier]
    private lazy var uniquifiers: [CoreDataEntityUniquifier] = lazyUniquifiers()

    @available(iOS 13.0, *)
    private lazy var historyProcessor: CoreDataPersistentHistoryProcessor = CoreDataPersistentHistoryProcessor(name: name, uniquifiers: uniquifiers)

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

    /// Handle remote store change notifications (.NSPersistentStoreRemoteChange).
    @objc
    @available(iOS 13.0, *)
    private func storeRemoteChange(_ notification: Notification) {
        logger.info("Merging changes from the other persistent store coordinator.")

        // Process persistent history to merge changes from other coordinators.
        historyQueue.addOperation {
            let taskContext = self.newBackgroundContext()
            taskContext.performAndWait {
                self.historyProcessor.processNewHistory(using: taskContext)
            }
        }
    }
}

extension NSManagedObjectContext: @unchecked Sendable {}
