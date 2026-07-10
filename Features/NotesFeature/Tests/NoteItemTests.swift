//
//  NoteItemTests.swift
//
//
//  Created by Mohamed Afifi on 2026-07-10.
//

import Foundation
import QuranAnnotations
import QuranKit
import XCTest
@testable import NotesFeature

final class NoteItemTests: XCTestCase {
    #if QURAN_SYNC
    func test_id_usesNoteID() {
        let first = item(note: note(id: "first", body: "First"))
        let second = item(note: note(id: "second", body: "Second"))

        XCTAssertEqual(first.id, "first")
        XCTAssertEqual(second.id, "second")
        XCTAssertNotEqual(first.id, second.id)
    }
    #else
    func test_id_usesVerseRange() {
        let first = item(note: note(body: "First"))
        let second = item(note: note(body: "Second"))

        XCTAssertEqual(first.id, second.id)
    }
    #endif

    #if QURAN_SYNC
    func test_noteText_returnsNoteBody() {
        XCTAssertEqual(item(note: note(id: "note", body: "Note body")).noteText, "Note body")
    }
    #else
    func test_noteText_normalizesNilBody() {
        XCTAssertEqual(item(note: note(body: nil)).noteText, "")
        XCTAssertEqual(item(note: note(body: "Note body")).noteText, "Note body")
    }
    #endif

    private func item(note: Note) -> NoteItem {
        NoteItem(note: note, verseText: "Verse text")
    }

    #if QURAN_SYNC
    private func note(id: String, body: String) -> Note {
        Note(
            id: id,
            note: body,
            startAyah: ayah,
            endAyah: ayah,
            modifiedDate: Date()
        )
    }
    #else
    private func note(body: String?) -> Note {
        Note(
            verses: [ayah],
            modifiedDate: Date(),
            note: body,
            color: .red
        )
    }
    #endif

    private var ayah: AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
    }
}
