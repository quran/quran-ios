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

        let description = stack.persistentContainer.persistentStoreDescriptions.first
        XCTAssertNotNil(description)
        XCTAssertEqual(description?.options[NSPersistentHistoryTrackingKey] as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(description?.options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(description?.shouldAddStoreAsynchronously, false)
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
