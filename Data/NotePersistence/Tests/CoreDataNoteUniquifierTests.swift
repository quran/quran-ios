//
//  CoreDataNoteUniquifierTests.swift
//
//
//  Created by Mohamed Afifi on 2023-06-01.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import NotePersistence
import SystemDependencies
import SystemDependenciesFake
import XCTest

class CoreDataNoteUniquifierTests: XCTestCase {
    var sut: CoreDataNoteUniquifier!
    var context: NSManagedObjectContext!
    var stack: CoreDataStack!

    var verse1: MO_Verse!
    var verse2: MO_Verse!
    var verse3: MO_Verse!
    var verse4: MO_Verse!

    var note1: MO_Note!
    var note2: MO_Note!
    var note3: MO_Note!

    override func setUp() async throws {
        try await super.setUp()

        stack = CoreDataStack.testingStack()
        context = stack.newBackgroundContext()

        verse1 = context.newVerse(sura: 1, ayah: 1)
        verse2 = context.newVerse(sura: 1, ayah: 2)
        verse3 = context.newVerse(sura: 1, ayah: 3)
        verse4 = context.newVerse(sura: 1, ayah: 4)

        note1 = context.newNote("Note 1", modifiedOn: 1)
        note2 = context.newNote("Note 2", modifiedOn: 2)
        note3 = context.newNote("Note 3", modifiedOn: 3)

        sut = CoreDataNoteUniquifier()
    }

    override func tearDown() {
        CoreDataStack.removePersistentFiles()
        sut = nil
        context = nil
        stack = nil
        super.tearDown()
    }

    func test_merge_shouldRemoveNotesWithNoVerses() throws {
        // Given
        try setUpNotesWithNoVerses()

        let insertedChange = PersistentHistoryChangeFake(object: note3, changeType: .insert)
        let transaction = PersistentHistoryTransactionFake(historyChanges: [insertedChange])

        // When
        XCTAssertNoThrow(try sut.merge(transactions: [transaction], using: context))

        // Then
        let notes = try context.allNotes()
        XCTAssertEqual(notes.map(\.note), ["Note 3", "Note 2"])
    }

    func test_merge_allNotesHaveVerses() throws {
        // Given
        try setUpAllNotesWithVerses()

        let insertedChange = PersistentHistoryChangeFake(object: note3, changeType: .insert)
        let transaction = PersistentHistoryTransactionFake(historyChanges: [insertedChange])

        // When
        XCTAssertNoThrow(try sut.merge(transactions: [transaction], using: context))

        // Then
        let notes = try context.allNotes()
        XCTAssertEqual(notes.map(\.note), ["Note 3", "Note 2", "Note 1"])
    }

    func test_merge_noRelatedNoteChange() throws {
        // Given
        try setUpAllNotesWithVerses()

        // When
        XCTAssertNoThrow(try sut.merge(transactions: [], using: context))

        // Then
        let notes = try context.allNotes()
        XCTAssertEqual(notes.map(\.note), ["Note 3", "Note 2", "Note 1"])
    }

    // MARK: - Helpers

    private func setUpNotesWithNoVerses() throws {
        note1.addToVerses(verse1)
        note2.addToVerses(verse2)
        note3.addToVerses(verse3)
        note3.addToVerses(verse1)
        try context.save()
    }

    private func setUpAllNotesWithVerses() throws {
        note1.addToVerses(verse1)
        note1.addToVerses(verse4)
        note2.addToVerses(verse2)
        note3.addToVerses(verse3)
        note3.addToVerses(verse1)
        try context.save()
    }
}
