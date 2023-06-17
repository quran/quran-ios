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
import SystemDependencies
import SystemDependenciesFake
import XCTest
@testable import LastPagePersistence

class CoreDataLastPageUniquifierTests: XCTestCase {
    var sut: CoreDataLastPageUniquifier!
    var context: NSManagedObjectContext!
    var stack: CoreDataStack!

    var entity1: MO_LastPage!
    var entity2: MO_LastPage!
    var entity3: MO_LastPage!
    var entity4: MO_LastPage!
    var entity5: MO_LastPage!

    override func setUp() async throws {
        try await super.setUp()

        stack = CoreDataStack.testingStack()
        context = stack.newBackgroundContext()

        entity1 = context.newLastPage(page: 45, modifiedOn: 1)
        entity2 = context.newLastPage(page: 500, modifiedOn: 2)
        entity3 = context.newLastPage(page: 100, modifiedOn: 3)
        entity4 = context.newLastPage(page: 250, modifiedOn: 4)
        entity5 = context.newLastPage(page: 190, modifiedOn: 5)

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
                PersistentHistoryChangeFake(object: entity1, changeType: .insert),
                PersistentHistoryChangeFake(object: entity4, changeType: .update),
                PersistentHistoryChangeFake(object: entity3, changeType: .insert),
            ]),
        ]
        XCTAssertNoThrow(try sut.merge(transactions: transactions, using: context))

        assertDatabaseContains([entity5, entity4, entity3])
    }

    func test_merge_noLastPageTransaction() throws {
        // Merge page bookmark translations
        let pageBookmark = context.newPageBookmark(page: 1, modifiedOn: 1)
        let transactions = [
            PersistentHistoryTransactionFake(historyChanges: [
                PersistentHistoryChangeFake(object: pageBookmark, changeType: .insert),
            ]),
        ]
        XCTAssertNoThrow(try sut.merge(transactions: transactions, using: context))

        assertDatabaseContains([entity5, entity4, entity3, entity2, entity1])
    }

    func test_merge_noOverflow() throws {
        context.delete(entity1)
        context.delete(entity2)
        context.delete(entity3)
        try context.save()

        assertDatabaseContains([entity5, entity4])

        // Merge page bookmark translations
        let transactions = [
            PersistentHistoryTransactionFake(historyChanges: [
                PersistentHistoryChangeFake(object: entity5, changeType: .insert),
            ]),
        ]
        XCTAssertNoThrow(try sut.merge(transactions: transactions, using: context))

        assertDatabaseContains([entity5, entity4])
    }

    private func assertDatabaseContains(
        _ entities: [MO_LastPage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            entities.map(\.page),
            try context.allLastPages().map(\.page),
            file: file,
            line: line
        )
    }
}
