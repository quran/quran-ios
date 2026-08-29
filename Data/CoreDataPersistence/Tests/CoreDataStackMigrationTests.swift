//
//  CoreDataStackMigrationTests.swift
//

import CoreData
import CoreDataModel
import XCTest
@testable import CoreDataPersistence

final class CoreDataStackMigrationTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataStackMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        storeURL = temporaryDirectory.appendingPathComponent("Quran.sqlite")
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
        try super.tearDownWithError()
    }

    func testAddingMushafIDMigratesExistingPagesToMadani() throws {
        let sourceModelURL = CoreDataModelResources.quranModel.appendingPathComponent("Quran.mom")
        var sourceStack: CoreDataStack? = makeStack(modelURL: sourceModelURL)
        try insertLegacyPage(entityName: "MO_PageBookmark", page: 300, into: try XCTUnwrap(sourceStack))
        try insertLegacyPage(entityName: "MO_LastPage", page: 400, into: try XCTUnwrap(sourceStack))
        sourceStack = nil

        let migratedStack = makeStack(modelURL: CoreDataModelResources.quranModel)

        XCTAssertEqual(try storedValues(entityName: "MO_PageBookmark", in: migratedStack), [
            StoredValues(page: 300, mushafID: 0),
        ])
        XCTAssertEqual(try storedValues(entityName: "MO_LastPage", in: migratedStack), [
            StoredValues(page: 400, mushafID: 0),
        ])
    }

    // MARK: Private

    private struct StoredValues: Equatable {
        let page: Int32
        let mushafID: Int16
    }

    private var temporaryDirectory: URL!
    private var storeURL: URL!

    private func makeStack(modelURL: URL) -> CoreDataStack {
        CoreDataStack(
            name: "QuranMigrationTest",
            modelUrl: modelURL,
            lazyUniquifiers: { [] },
            persistentStoreLoader: { [storeURL] container in
                container.persistentStoreDescriptions.first?.url = storeURL
                var loadError: NSError?
                container.loadPersistentStores { _, error in
                    loadError = error as NSError?
                }
                return loadError
            }
        )
    }

    private func insertLegacyPage(
        entityName: String,
        page: Int32,
        into stack: CoreDataStack
    ) throws {
        let context = stack.newBackgroundContext()
        try context.performAndWait {
            let entity = try XCTUnwrap(NSEntityDescription.entity(forEntityName: entityName, in: context))
            let object = NSManagedObject(entity: entity, insertInto: context)
            object.setValue(page, forKey: "page")
            object.setValue(Date(timeIntervalSince1970: 1000), forKey: "createdOn")
            object.setValue(Date(timeIntervalSince1970: 2000), forKey: "modifiedOn")
            try context.save()
        }
    }

    private func storedValues(
        entityName: String,
        in stack: CoreDataStack
    ) throws -> [StoredValues] {
        let context = stack.newBackgroundContext()
        return try context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            return try context.fetch(request).map {
                StoredValues(
                    page: try XCTUnwrap($0.value(forKey: "page") as? NSNumber).int32Value,
                    mushafID: try XCTUnwrap($0.value(forKey: "mushafID") as? NSNumber).int16Value
                )
            }
        }
    }
}
