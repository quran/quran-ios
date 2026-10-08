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
    func test_persistentContainerCreated() throws {
        let stack = try makeStack { container in
            container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
            return CoreDataStack.loadPersistentStores(in: container)
        }

        let context = stack.newBackgroundContext()
        XCTAssertEqual(context.transactionAuthor, "app")
        XCTAssertIdentical(context.mergePolicy as AnyObject, NSMergeByPropertyObjectTrumpMergePolicy)

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

        CoreDataStack.configurePersistentStores(in: container, name: "ConfigurationTests")

        XCTAssertTrue(container.persistentStoreDescriptions.allSatisfy { description in
            !description.shouldAddStoreAsynchronously &&
                description.options[NSPersistentHistoryTrackingKey] as? NSNumber == NSNumber(value: true) &&
                description.options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber == NSNumber(value: true)
        })
    }

    func test_sqliteMisuseReloadsStoreWithFreshContainer() throws {
        var attempts = 0
        var containers: [NSPersistentContainer] = []
        let stack = try makeStack { container in
            attempts += 1
            containers.append(container)
            guard attempts > 1 else {
                return NSError(domain: "NSSQLiteErrorDomain", code: 21)
            }
            container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
            return CoreDataStack.loadPersistentStores(in: container)
        }

        XCTAssertEqual(attempts, 2)
        XCTAssertFalse(containers[0] === containers[1])
        XCTAssertIdentical(stack.persistentContainer, containers[1])
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

    // MARK: Private

    private func makeStack(persistentStoreLoader: (NSPersistentContainer) -> NSError?) throws -> CoreDataStack {
        try CoreDataStack(
            name: "CoreDataStackTests-\(UUID().uuidString)",
            modelUrl: CoreDataModelResources.quranModel,
            lazyUniquifiers: { [] },
            persistentStoreLoader: persistentStoreLoader,
            onChange: {}
        )
    }
}
