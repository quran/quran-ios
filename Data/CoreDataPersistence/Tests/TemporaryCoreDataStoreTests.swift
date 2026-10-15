//
//  TemporaryCoreDataStoreTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import XCTest
@testable import CoreDataPersistenceTestSupport

final class TemporaryCoreDataStoreTests: XCTestCase {
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

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

    func test_drainPendingRemovals_waitsForReleasedStores() throws {
        let releasedURL = try autoreleasepool {
            let released = TemporaryCoreDataStore()
            try released.stack().write { context in
                _ = context.newNote("Released", modifiedOn: 1)
            }
            return released.storeURL
        }

        TemporaryCoreDataStore.drainPendingRemovals(timeout: 10)

        XCTAssertFalse(FileManager.default.fileExists(atPath: releasedURL.path))
    }

    func test_removeStores_removesStoresLeftUntouched() throws {
        let leftover = "TemporaryCoreDataStore-\(UUID().uuidString)"
        try createFiles(["\(leftover).sqlite", "\(leftover).sqlite-wal", "\(leftover)/token.data"], modifiedOn: twoHoursAgo)

        TemporaryCoreDataStore.removeStores(in: directory, modifiedBefore: oneHourAgo)

        XCTAssertEqual(try contents(), [])
    }

    func test_removeStores_keepsStoresWithARecentFile() throws {
        let inUse = "TemporaryCoreDataStore-\(UUID().uuidString)"
        let inUseHistory = "TemporaryCoreDataStore-\(UUID().uuidString)"
        try createFiles(["\(inUse).sqlite", "\(inUseHistory).sqlite", "\(inUseHistory)/token.data"], modifiedOn: twoHoursAgo)
        try createFiles(["\(inUse).sqlite-wal"], modifiedOn: Date())
        try setModificationDate(Date(), of: "\(inUseHistory)/token.data")

        TemporaryCoreDataStore.removeStores(in: directory, modifiedBefore: oneHourAgo)

        XCTAssertEqual(try contents(), [inUse + ".sqlite", inUse + ".sqlite-wal", inUseHistory, inUseHistory + ".sqlite"].sorted())
    }

    func test_removeStores_keepsOtherFiles() throws {
        try createFiles(["Quran.sqlite", "TemporaryCoreDataStore.txt"], modifiedOn: twoHoursAgo)

        TemporaryCoreDataStore.removeStores(in: directory, modifiedBefore: oneHourAgo)

        XCTAssertEqual(try contents(), ["Quran.sqlite", "TemporaryCoreDataStore.txt"])
    }

    // MARK: Private

    private var directory: URL!
    private let oneHourAgo = Date().addingTimeInterval(-60 * 60)
    private let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)

    private func createFiles(_ paths: [String], modifiedOn date: Date) throws {
        for path in paths {
            let url = directory.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data().write(to: url)
        }
        // Sets files first, since adding a file changes its directory's date.
        for path in paths {
            try setModificationDate(date, of: path)
        }
        for path in paths where path.contains("/") {
            try setModificationDate(date, of: (path as NSString).deletingLastPathComponent)
        }
    }

    private func setModificationDate(_ date: Date, of path: String) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: directory.appendingPathComponent(path).path)
    }

    private func contents() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
    }

    private func notes(in stack: CoreDataStack) throws -> [String?] {
        let context = stack.newBackgroundContext()
        return try context.performAndWait {
            try context.allNotes().map(\.note)
        }
    }
}
