//
//  CoreDataInsertedEntitiesRetriever.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreData
import CoreDataModel
import SystemDependencies
import SystemDependenciesFake
import XCTest
@testable import CoreDataPersistence

class CoreDataInsertedEntitiesRetrieverTests: XCTestCase {
    var sut: CoreDataInsertedEntitiesRetriever<MO_LastPage>!
    var transactions: [PersistentHistoryTransaction]!
    var context: NSManagedObjectContext!
    var stack: CoreDataStack!
    var object1: MO_LastPage!
    var object2: MO_LastPage!
    var object3: MO_LastPage!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack.testingStack()
        context = stack.newBackgroundContext()

        object1 = MO_LastPage(context: context)
        object2 = MO_LastPage(context: context)
        object3 = MO_LastPage(context: context)

        sut = CoreDataInsertedEntitiesRetriever()

        // Create a list of changes, including insertions, modifications and deletions
        let insertedChange = PersistentHistoryChangeFake(object: object1, changeType: .insert)
        let updatedChange = PersistentHistoryChangeFake(object: object2, changeType: .update)
        let deletedChange = PersistentHistoryChangeFake(object: object3, changeType: .delete)

        // Create mock transactions
        let transaction1 = PersistentHistoryTransactionFake(historyChanges: [insertedChange, updatedChange])
        let transaction2 = PersistentHistoryTransactionFake(historyChanges: [deletedChange])

        transactions = [transaction1, transaction2]
    }

    override func tearDown() {
        CoreDataStack.removePersistentFiles()
        sut = nil
        transactions = nil
        context = nil
        stack = nil
        super.tearDown()
    }

    func test_findingInsertedEntities() {
        let insertedEntities = sut.insertedEntities(transactions: transactions)

        // Check that the method correctly identified the inserted entities.
        XCTAssertEqual(insertedEntities, [object1.objectID])
    }
}
