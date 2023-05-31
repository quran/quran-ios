//
//  CoreDataLastPageUniquifierTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import CoreDataPersistenceTestSupport
@testable import LastPagePersistence
import SystemDependencies
import SystemDependenciesFake
import XCTest

class CoreDataLastPageUniquifierTests: XCTestCase {
    var sut: CoreDataLastPageUniquifier!
    var context: NSManagedObjectContext!
    var stack: CoreDataStack!

    var entity1: LastPageEntity!
    var entity2: LastPageEntity!
    var entity3: LastPageEntity!
    var entity4: LastPageEntity!
    var entity5: LastPageEntity!

    override func setUp() async throws {
        try await super.setUp()

        stack = CoreDataStack.testingStack()
        context = stack.newBackgroundContext()

        entity1 = LastPageEntity(context: context, page: 45, modifiedOn: 1)
        entity2 = LastPageEntity(context: context, page: 500, modifiedOn: 2)
        entity3 = LastPageEntity(context: context, page: 100, modifiedOn: 3)
        entity4 = LastPageEntity(context: context, page: 250, modifiedOn: 4)
        entity5 = LastPageEntity(context: context, page: 190, modifiedOn: 5)

        try context.save()

        sut = CoreDataLastPageUniquifier()
    }

    override func tearDown() {
        CoreDataStack.removePersistentFiles()
        sut = nil
        context = nil
        stack = nil
        super.tearDown()
    }

    func test_merge_removingOverflow() throws {
        assertDatabaseContains([entity5, entity4, entity3, entity2, entity1])

        // Merge transactions
        let transactions = [
            PersistentHistoryTransactionFake(historyChanges: [
                PersistentHistoryChangeFake(entity: entity1, changeType: .insert),
                PersistentHistoryChangeFake(entity: entity4, changeType: .update),
                PersistentHistoryChangeFake(entity: entity3, changeType: .insert),
            ]),
        ]
        XCTAssertNoThrow(try sut.merge(transactions: transactions, using: context))

        assertDatabaseContains([entity5, entity4, entity3])
    }

    func test_merge_noLastPageTransaction() throws {
        // Merge page bookmark translations
        let pageBookmark = PageBookmarkEntity(context: context, page: 1, modifiedOn: 1)
        let transactions = [
            PersistentHistoryTransactionFake(historyChanges: [
                PersistentHistoryChangeFake(entity: pageBookmark, changeType: .insert),
            ]),
        ]
        XCTAssertNoThrow(try sut.merge(transactions: transactions, using: context))

        assertDatabaseContains([entity5, entity4, entity3, entity2, entity1])
    }

    func test_merge_noOverflow() throws {
        context.delete(entity1.object)
        context.delete(entity2.object)
        context.delete(entity3.object)
        try context.save()

        assertDatabaseContains([entity5, entity4])

        // Merge page bookmark translations
        let transactions = [
            PersistentHistoryTransactionFake(historyChanges: [
                PersistentHistoryChangeFake(entity: entity5, changeType: .insert),
            ]),
        ]
        XCTAssertNoThrow(try sut.merge(transactions: transactions, using: context))

        assertDatabaseContains([entity5, entity4])
    }

    private func assertDatabaseContains(_ entities: [LastPageEntity],
                                        file: StaticString = #filePath, line: UInt = #line)
    {
        XCTAssertEqual(entities.map(\.page),
                       try context.allLastPages().map(\.page),
                       file: file, line: line)
    }
}
