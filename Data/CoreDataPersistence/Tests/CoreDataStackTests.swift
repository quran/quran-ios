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
    }
}
