//
//  CoreDataStoreTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import CoreData
import CoreDataModel
import Utilities
import XCTest
@testable import CoreDataPersistence

final class CoreDataStoreTests: XCTestCase {
    // MARK: Internal

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        try super.tearDownWithError()
    }

    func test_stack_loadsAgainAfterAFailure() async throws {
        let isStorageFull = ManagedCriticalState(true)
        let store = makeStore { container in
            isStorageFull.withCriticalRegion { $0 } ? Self.storageFullError : Self.loadInMemory(container)
        }
        do {
            _ = try await store.stack()
            XCTFail("Expected the load to fail")
        } catch {
            XCTAssertTrue(PersistentStoreFailure.isStorageFull(error))
        }

        isStorageFull.withCriticalRegion { $0 = false }
        let stack = try await store.stack()

        XCTAssertEqual(stack.persistentContainer.persistentStoreCoordinator.persistentStores.count, 1)
    }

    func test_stack_isLoadedOnceForConcurrentCalls() async throws {
        let loads = ManagedCriticalState(0)
        let store = makeStore { container in
            loads.withCriticalRegion { $0 += 1 }
            return Self.loadInMemory(container)
        }

        async let first = store.stack()
        async let second = store.stack()
        let stacks = try await [first, second]

        XCTAssertIdentical(stacks[0], stacks[1])
        XCTAssertEqual(loads.withCriticalRegion { $0 }, 1)
    }

    @MainActor
    func test_stack_loadsOffTheMainThread() async throws {
        let loadedOnMainThread = ManagedCriticalState<Bool?>(nil)
        let store = makeStore { container in
            loadedOnMainThread.withCriticalRegion { $0 = Thread.isMainThread }
            return Self.loadInMemory(container)
        }

        _ = try await store.stack()

        XCTAssertEqual(loadedOnMainThread.withCriticalRegion { $0 }, false)
    }

    func test_changes_emitsWhenTheStoreChanges() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataStoreChangesTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryDirectory = directory
        let store = makeStore { container in
            container.persistentStoreDescriptions.first?.url = directory.appendingPathComponent("Quran.sqlite")
            return CoreDataStack.loadPersistentStores(in: container)
        }

        // Subscribe before the store loads.
        let changes = store.changes()
        let changed = expectation(description: "The store reports a change")
        let task = Task {
            for await _ in changes {
                changed.fulfill()
                return
            }
        }
        defer { task.cancel() }

        let context = try await store.stack().newBackgroundContext()
        try await context.perform { context in
            let note = MO_Note(context: context)
            note.note = "Arrived"
            try context.save()
        }

        await fulfillment(of: [changed], timeout: 5)
    }

    // MARK: Private

    /// The shape Core Data reports when SQLite can't write to a full device.
    private static let storageFullError = NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: [
        NSFilePathErrorKey: "/var/mobile/Containers/Data/Application/Library/Application Support/Quran.sqlite",
        "NSSQLiteErrorDomain": 13,
    ])

    private var temporaryDirectory: URL?

    private static func loadInMemory(_ container: NSPersistentContainer) -> NSError? {
        container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
        return CoreDataStack.loadPersistentStores(in: container)
    }

    private func makeStore(persistentStoreLoader: @escaping @Sendable (NSPersistentContainer) -> NSError?) -> CoreDataStore {
        CoreDataStore(
            name: "CoreDataStoreTests-\(UUID().uuidString)",
            modelUrl: CoreDataModelResources.quranModel,
            lazyUniquifiers: { [] },
            persistentStoreLoader: persistentStoreLoader
        )
    }
}
