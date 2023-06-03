//
//  CoreDataPublisherTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import Combine
import CoreData
import CoreDataModel
@testable import CoreDataPersistence
import TestUtilities
import XCTest

class CoreDataPublisherTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var context: NSManagedObjectContext!
    var cancellables = Set<AnyCancellable>()
    var request: NSFetchRequest<MO_Note>!

    override func setUp() {
        super.setUp()
        // Instantiating your CoreDataStack
        coreDataStack = CoreDataStack.testingStack()
        context = coreDataStack.newBackgroundContext()

        request = MO_Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.Note.modifiedOn, ascending: false)]
    }

    override func tearDown() {
        super.tearDown()
        cancellables.removeAll()
        // Clean up after each test
        CoreDataStack.removePersistentFiles()
        coreDataStack = nil
    }

    func test_initialValues() throws {
        // Given
        let publisher = CoreDataPublisher(request: request, context: context)

        // Verify
        XCTAssertEqual([[]], try awaitPublisher(publisher, numberOfElements: 1))

        // Create new note.
        let note = insertNewNote("Hello, world!", modifiedOn: 1945)
        try context.save()

        // Verify
        XCTAssertEqual([[note.note]], try awaitPublisher(publisher, numberOfElements: 1).map { $0.map(\.note) })
    }

    func test_valuesUpdateOverTime() throws {
        // Given
        let publisher = CoreDataPublisher(request: request, context: context)

        let expectation = expectation(description: "Awaiting publisher")

        var elements = [[MO_Note]]()
        let cancellable = publisher.sink { value in
            elements.append(value)
            if elements.count == 2 {
                expectation.fulfill()
            }
        }

        // Create two notes.
        let note1 = insertNewNote("Hello, world!", modifiedOn: 1945)
        let note2 = insertNewNote("Welcome!", modifiedOn: 100)
        try context.save()

        wait(for: [expectation], timeout: 5)
        cancellable.cancel()

        XCTAssertEqual([[], [note1.note, note2.note]], elements.map { $0.map(\.note) })
    }

    // MARK: - Helpers

    func insertNewNote(_ text: String, modifiedOn: TimeInterval) -> MO_Note {
        let note = MO_Note(context: context)
        note.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
        note.note = text
        return note
    }
}
