//
//  CoreDataNotePersistenceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-31.
//

import AsyncUtilitiesForTesting
import Combine
import CoreDataPersistence
import SystemDependenciesFake
import XCTest
@testable import NotePersistence

class CoreDataNotePersistenceTests: XCTestCase {
    var sut: CoreDataNotePersistence!
    var stack: CoreDataStack!
    var time: SystemTimeFake!

    var verse1: VersePersistenceModel!
    var verse2: VersePersistenceModel!
    var verse3: VersePersistenceModel!
    var verse4: VersePersistenceModel!

    var note1: NotePersistenceModel!
    var note2: NotePersistenceModel!
    var note3: NotePersistenceModel!

    override func setUp() async throws {
        try await super.setUp()

        stack = CoreDataStack.testingStack()
        time = SystemTimeFake()

        verse1 = VersePersistenceModel(ayah: 1, sura: 1)
        verse2 = VersePersistenceModel(ayah: 2, sura: 1)
        verse3 = VersePersistenceModel(ayah: 3, sura: 1)
        verse4 = VersePersistenceModel(ayah: 4, sura: 1)

        note1 = NotePersistenceModel("Note 1", color: 1, modifiedDate: Date(timeIntervalSince1970: 100))
        note2 = NotePersistenceModel("", color: 2, modifiedDate: Date(timeIntervalSince1970: 200))
        note3 = NotePersistenceModel("Note 3", color: 3, modifiedDate: Date(timeIntervalSince1970: 300))

        sut = CoreDataNotePersistence(stack: stack, time: time)
    }

    override func tearDown() {
        CoreDataStack.removePersistentFiles()
        sut = nil
        stack = nil
        super.tearDown()
    }

    func test_createAndRetrieveNotes() async throws {
        // 1. Initially empty.
        let collector = PublisherCollector(sut.notes())
        XCTAssertEqual(collector.items.count, 1)
        XCTAssertEqual(collector.items.last, [])

        // 2. Create a note
        time.now = note1.modifiedDate
        let returnedNote1 = try await sut.setNote(note1.note, verses: [verse1, verse2], color: note1.color)

        // 3. Assert created note
        note1.verses = [verse1, verse2]
        XCTAssertEqual(returnedNote1, note1)
        XCTAssertEqual(collector.items.last, [returnedNote1])

        // 4. Create a nother note
        time.now = note2.modifiedDate
        let returnedNote2 = try await sut.setNote(note2.note, verses: [verse3], color: note2.color)

        // 5. Assert created note
        note2.verses = [verse3]
        XCTAssertEqual(returnedNote2, note2)
        XCTAssertEqual(collector.items.last, [returnedNote2, returnedNote1])

        // 6. Create new note merging an existing one.
        time.now = note3.modifiedDate
        let returnedNote3 = try await sut.setNote(note3.note, verses: [verse1, verse4], color: note3.color)

        // 7. Assert merged note
        note3.verses = [verse1, verse2, verse4]
        XCTAssertEqual(returnedNote3, note3)
        XCTAssertEqual(collector.items.last, [returnedNote3, returnedNote2])

        // 8. Delete a note
        let deletedNotes1 = try await sut.removeNotes(with: [verse1])
        XCTAssertEqual(deletedNotes1, [returnedNote3])

        // 9. Updating existing note with same data, won't modify it.
        let numberOfUpdates = collector.items.count
        time.now = Date()
        let updatedNote2 = try await sut.setNote(note2.note, verses: Array(note2.verses), color: note2.color)

        // 10. Assert no change to database
        XCTAssertEqual(updatedNote2, returnedNote2)
        XCTAssertEqual(numberOfUpdates, collector.items.count)
    }
}

extension NotePersistenceModel {
    init(_ text: String?, color: Int, modifiedDate: Date) {
        self.init(verses: [], modifiedDate: modifiedDate, note: text, color: color)
    }
}
