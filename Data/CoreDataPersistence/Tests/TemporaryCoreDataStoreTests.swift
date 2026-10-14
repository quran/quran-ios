//
//  TemporaryCoreDataStoreTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import XCTest

final class TemporaryCoreDataStoreTests: XCTestCase {
    func test_storesDoNotShareData() throws {
        let store1 = TemporaryCoreDataStore()
        let store2 = TemporaryCoreDataStore()
        let stack1 = store1.stack()
        let stack2 = store2.stack()

        try stack1.write { context in
            _ = context.newNote("First store", modifiedOn: 1)
        }

        XCTAssertNotEqual(store1.storeURL, store2.storeURL)
        XCTAssertEqual(try notes(in: stack1), ["First store"])
        XCTAssertEqual(try notes(in: stack2), [])
    }

    func test_release_removesOnlyItsOwnStore() throws {
        let kept = TemporaryCoreDataStore()
        let keptStack = kept.stack()
        try keptStack.write { context in
            _ = context.newNote("Kept", modifiedOn: 1)
        }
        // Drains the objects Core Data autoreleases, so the released store's coordinator can close.
        let releasedURL = try autoreleasepool {
            let released = TemporaryCoreDataStore()
            try released.stack().write { context in
                _ = context.newNote("Released", modifiedOn: 2)
            }
            XCTAssertTrue(FileManager.default.fileExists(atPath: released.storeURL.path))
            return released.storeURL
        }

        let removed = expectation(
            for: NSPredicate { _, _ in !FileManager.default.fileExists(atPath: releasedURL.path) },
            evaluatedWith: nil
        )
        wait(for: [removed], timeout: 10)

        XCTAssertTrue(FileManager.default.fileExists(atPath: kept.storeURL.path))
        XCTAssertEqual(try notes(in: keptStack), ["Kept"])
    }

    // MARK: Private

    private func notes(in stack: CoreDataStack) throws -> [String?] {
        let context = stack.newBackgroundContext()
        return try context.performAndWait {
            try context.allNotes().map(\.note)
        }
    }
}
