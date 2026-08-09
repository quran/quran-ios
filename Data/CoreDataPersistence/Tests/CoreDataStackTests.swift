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

    override func setUp() {
        super.setUp()
        stack = CoreDataStack.testingStack()
    }

    override func tearDown() {
        stack = nil
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
