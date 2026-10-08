//
//  CoreDataContextTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import AsyncUtilitiesForTesting
import Combine
import CoreData
import CoreDataModel
import Utilities
import XCTest
@testable import CoreDataPersistence

final class CoreDataContextTests: XCTestCase {
    // MARK: Internal

    func test_perform_throwsWhenTheStoreCannotOpen_thenRunsOnceItOpens() async throws {
        let isStorageFull = ManagedCriticalState(true)
        let sut = CoreDataContext(store: makeStore { container in
            isStorageFull.withCriticalRegion { $0 } ? Self.storageFullError : Self.loadInMemory(container)
        })

        do {
            try await sut.perform { _ in }
            XCTFail("Expected the store to fail to open")
        } catch {
            XCTAssertTrue(PersistentStoreFailure.isStorageFull(error))
        }

        isStorageFull.withCriticalRegion { $0 = false }
        let author = try await sut.perform { context in context.transactionAuthor }
        XCTAssertEqual(author, "app")
    }

    func test_publisher_emitsOnceTheStoreOpens() async {
        let sut = CoreDataContext(store: makeStore { Self.loadInMemory($0) })
        let emitted = expectation(description: "The publisher emits")

        let cancellable = sut.publisher(for: Self.notesRequest()).sink { notes in
            XCTAssertEqual(notes, [])
            emitted.fulfill()
        }
        defer { cancellable.cancel() }

        await fulfillment(of: [emitted], timeout: 5)
    }

    func test_publisher_subscribedBeforeTheStoreOpens_seesWritesThroughPerform() async throws {
        let sut = CoreDataContext(store: makeStore { Self.loadInMemory($0) })
        let emittedNote = expectation(description: "The publisher emits the written note")
        let cancellable = sut.publisher(for: Self.notesRequest()).sink { notes in
            if notes.map(\.note) == ["Written"] {
                emittedNote.fulfill()
            }
        }
        defer { cancellable.cancel() }

        try await sut.perform { context in
            let note = MO_Note(context: context)
            note.note = "Written"
            note.modifiedOn = Date()
            try context.save()
        }

        await fulfillment(of: [emittedNote], timeout: 5)
    }

    func test_publisher_emitsRightAwayWhenTheStoreIsOpen() async throws {
        let store = makeStore { Self.loadInMemory($0) }
        _ = try await store.stack()
        let sut = CoreDataContext(store: store)

        let collector = PublisherCollector(sut.publisher(for: Self.notesRequest()))

        XCTAssertEqual(collector.items, [[]])
    }

    func test_publisher_emitsNothingWhenTheStoreCannotOpen() async {
        let attempted = expectation(description: "The store tried to open")
        let sut = CoreDataContext(store: makeStore { _ in
            attempted.fulfill()
            return Self.storageFullError
        })

        let collector = PublisherCollector(sut.publisher(for: Self.notesRequest()))
        await fulfillment(of: [attempted], timeout: 5)
        // A bounded negative check: gives the failed open time to finish before checking nothing arrived.
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(collector.items, [])
    }

    // MARK: Private

    private static let storageFullError = NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: [
        NSFilePathErrorKey: "/var/mobile/Containers/Data/Application/Library/Application Support/Quran.sqlite",
        "NSSQLiteErrorDomain": 13,
    ])

    private static func notesRequest() -> NSFetchRequest<MO_Note> {
        let request = MO_Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.Note.modifiedOn, ascending: false)]
        return request
    }

    private static func loadInMemory(_ container: NSPersistentContainer) -> NSError? {
        container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
        return CoreDataStack.loadPersistentStores(in: container)
    }

    private func makeStore(persistentStoreLoader: @escaping @Sendable (NSPersistentContainer) -> NSError?) -> CoreDataStore {
        CoreDataStore(
            name: "CoreDataContextTests-\(UUID().uuidString)",
            modelUrl: CoreDataModelResources.quranModel,
            lazyUniquifiers: { [] },
            persistentStoreLoader: persistentStoreLoader
        )
    }
}
