//
//  CoreDataStackTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreData
import CoreDataModel
import XCTest
@testable import CoreDataPersistence

class CoreDataStackTests: XCTestCase {
    var stack: CoreDataStack!
    var temporaryDirectory: URL?

    override func setUp() {
        super.setUp()
        stack = CoreDataStack.testingStack()
    }

    override func tearDown() {
        stack = nil
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        super.tearDown()
    }

    func test_persistentContainerCreated() {
        XCTAssertNotNil(stack.persistentContainer)

        XCTAssertIdentical(stack.viewContext.mergePolicy as AnyObject, NSMergeByPropertyObjectTrumpMergePolicy)
        XCTAssertEqual(stack.viewContext.transactionAuthor, "app")
        XCTAssertTrue(stack.viewContext.automaticallyMergesChangesFromParent)

        let context = stack.newBackgroundContext()
        XCTAssertEqual(context.transactionAuthor, "app")

        let descriptions = stack.persistentContainer.persistentStoreDescriptions
        XCTAssertFalse(descriptions.isEmpty)
        for description in descriptions {
            XCTAssertEqual(description.options[NSPersistentHistoryTrackingKey] as? NSNumber, NSNumber(value: true))
            XCTAssertEqual(description.options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber, NSNumber(value: true))
            XCTAssertFalse(description.shouldAddStoreAsynchronously)
        }
    }

    func test_configurePersistentStoresConfiguresEveryDescriptionSynchronously() throws {
        let container = NSPersistentContainer(
            name: "ConfigurationTests",
            managedObjectModel: try XCTUnwrap(NSManagedObjectModel(contentsOf: CoreDataModelResources.quranModel))
        )
        container.persistentStoreDescriptions = [
            NSPersistentStoreDescription(),
            NSPersistentStoreDescription(),
        ]
        container.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = true }

        stack.configurePersistentStores(in: container)

        XCTAssertTrue(container.persistentStoreDescriptions.allSatisfy { description in
            !description.shouldAddStoreAsynchronously &&
                description.options[NSPersistentHistoryTrackingKey] as? NSNumber == NSNumber(value: true) &&
                description.options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber == NSNumber(value: true)
        })
    }

    func test_sqliteMisuseReloadsStoreWithFreshContainer() {
        var attempts = 0
        var containers: [NSPersistentContainer] = []
        stack = CoreDataStack(
            name: "CoreDataStackRetryTests-\(UUID().uuidString)",
            modelUrl: CoreDataModelResources.quranModel,
            lazyUniquifiers: { [] },
            persistentStoreLoader: { container in
                attempts += 1
                containers.append(container)
                guard attempts > 1 else {
                    return NSError(domain: "NSSQLiteErrorDomain", code: 21)
                }

                container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
                var loadError: NSError?
                container.loadPersistentStores { _, error in
                    loadError = error as NSError?
                }
                return loadError
            }
        )

        XCTAssertNotNil(stack.persistentContainer)
        XCTAssertEqual(attempts, 2)
        XCTAssertEqual(containers.count, 2)
        XCTAssertFalse(containers[0] === containers[1])
    }

    func test_openBackgroundContext_throwsLoadFailureAndLoadsOnRetry() throws {
        var isProtectedDataAvailable = false
        stack = CoreDataStack(
            name: "CoreDataStackRecoverableTests-\(UUID().uuidString)",
            modelUrl: CoreDataModelResources.quranModel,
            lazyUniquifiers: { [] },
            persistentStoreLoader: { container in
                guard isProtectedDataAvailable else {
                    return NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
                }
                container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
                var loadError: NSError?
                container.loadPersistentStores { _, error in
                    loadError = error as NSError?
                }
                return loadError
            }
        )

        XCTAssertThrowsError(try stack.openBackgroundContext()) { error in
            XCTAssertEqual((error as NSError).code, NSFileReadNoPermissionError)
        }

        isProtectedDataAvailable = true
        let context = try stack.openBackgroundContext()
        XCTAssertEqual(context.transactionAuthor, "app")
        XCTAssertIdentical(try stack.openBackgroundContext().persistentStoreCoordinator, context.persistentStoreCoordinator)
    }

    func test_changes_emitsWhenTheStoreChanges() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataStackChangesTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryDirectory = directory
        stack = CoreDataStack(
            name: "CoreDataStackChangesTests",
            modelUrl: CoreDataModelResources.quranModel,
            lazyUniquifiers: { [] },
            persistentStoreLoader: { container in
                container.persistentStoreDescriptions.first?.url = directory.appendingPathComponent("Quran.sqlite")
                var loadError: NSError?
                container.loadPersistentStores { _, error in
                    loadError = error as NSError?
                }
                return loadError
            }
        )

        // Subscribe before the store loads.
        let changes = stack.changes()
        let changed = expectation(description: "The store reports a change")
        let task = Task {
            for await _ in changes {
                changed.fulfill()
                return
            }
        }
        defer { task.cancel() }

        let context = stack.newBackgroundContext()
        try context.performAndWait {
            let note = MO_Note(context: context)
            note.note = "Arrived"
            try context.save()
        }

        wait(for: [changed], timeout: 5)
    }

    func test_storeLoadRecoveryOnlyRetriesFirstSQLiteMisuse() {
        XCTAssertTrue(PersistentStoreLoadRecovery.shouldRetry(
            NSError(domain: "NSSQLiteErrorDomain", code: 21),
            attempt: 1
        ))
        XCTAssertFalse(PersistentStoreLoadRecovery.shouldRetry(
            NSError(domain: "NSSQLiteErrorDomain", code: 21),
            attempt: 2
        ))
        XCTAssertFalse(PersistentStoreLoadRecovery.shouldRetry(
            NSError(domain: NSCocoaErrorDomain, code: 256),
            attempt: 1
        ))
    }
}
