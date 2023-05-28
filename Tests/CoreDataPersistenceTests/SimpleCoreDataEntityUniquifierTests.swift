//
//  SimpleCoreDataEntityUniquifierTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreData
import CoreDataModel
@testable import CoreDataPersistence
import SystemDependencies
import SystemDependenciesFake
import XCTest

class SimpleCoreDataEntityUniquifierTests: XCTestCase {
    var sut: SimpleCoreDataEntityUniquifier<MO_PageBookmark>!
    var transactions: [PersistentHistoryTransaction]!
    var context: NSManagedObjectContext!
    var stack: CoreDataStack!

    var existingEntity: PageBookmarkEntity!
    var entity1: PageBookmarkEntity!
    var entity2: PageBookmarkEntity!
    var entity3: PageBookmarkEntity!

    override func setUp() async throws {
        try await super.setUp()

        stack = CoreDataStack.testingStack()
        context = stack.newBackgroundContext()

        existingEntity = PageBookmarkEntity(context: context, page: 45, modifiedOn: 100)
        entity1 = PageBookmarkEntity(context: context, page: 45, modifiedOn: 120)
        entity2 = PageBookmarkEntity(context: context, page: 500, modifiedOn: 1945)
        entity3 = PageBookmarkEntity(context: context, page: 100, modifiedOn: 5555)

        // Delete the 3rd entity entity
        context.delete(entity3.object)
        try context.save()

        // Create a list of changes, including insertions, modifications and deletions
        let insertedChange = PersistentHistoryChangeFake(entity: entity1, changeType: .insert)
        let updatedChange = PersistentHistoryChangeFake(entity: entity2, changeType: .update)
        let deletedChange = PersistentHistoryChangeFake(entity: entity3, changeType: .delete)

        // Create mock transactions
        let transaction1 = PersistentHistoryTransactionFake(historyChanges: [insertedChange, updatedChange])
        let transaction2 = PersistentHistoryTransactionFake(historyChanges: [deletedChange])
        transactions = [transaction1, transaction2]

        sut = SimpleCoreDataEntityUniquifier(
            sortBy: Schema.PageBookmark.modifiedOn,
            ascending: false,
            key: .page
        )
    }

    override func tearDown() {
        CoreDataStack.removePersistentFiles()
        sut = nil
        transactions = nil
        context = nil
        stack = nil
        super.tearDown()
    }

    func test_merge() throws {
        XCTAssertEqual([45, 45, 500], try context.allPageBookmarks().map(\.page))

        XCTAssertNoThrow(try sut.merge(transactions: transactions, using: context))

        let fetchRequest = MO_PageBookmark.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.modifiedOn, ascending: true)]
        let pages = try stack.newBackgroundContext().allPageBookmarks()
        XCTAssertEqual([45, 500], pages.map(\.page))
    }
}
