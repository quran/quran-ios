#if QURAN_SYNC
//
//  SyncedNoteCounterTests.swift
//  Quran
//
//  Created by Ahmed Nabil on 2026-05-20.
//

import QuranKit
import XCTest
@testable import AnnotationsService
@testable import QuranAnnotations
@testable import QuranViewFeature

final class SyncedNoteCounterTests: XCTestCase {
    func test_count_returnsZero_whenNoNotes() {
        XCTAssertEqual(SyncedNoteCounter.count([], interacting: [ayah(1)]), 0)
    }

    func test_count_countsMultipleNotesForSameAyah() {
        let notes = [note(id: "1", start: ayah(1)), note(id: "2", start: ayah(1))]

        XCTAssertEqual(SyncedNoteCounter.count(notes, interacting: [ayah(1)]), 2)
    }

    func test_count_countsMultiAyahNoteOverlappingSelection() {
        let notes = [note(start: ayah(1), end: ayah(3))]

        XCTAssertEqual(SyncedNoteCounter.count(notes, interacting: [ayah(2)]), 1)
    }

    func test_count_skipsNonOverlappingNotes() {
        let notes = [note(start: ayah(1), end: ayah(2))]

        XCTAssertEqual(SyncedNoteCounter.count(notes, interacting: [ayah(3)]), 0)
    }

    private func note(id: String = "note", start: AyahNumber, end: AyahNumber? = nil) -> Note {
        Note(
            localId: id,
            note: "Note body",
            startAyah: start,
            endAyah: end ?? start,
            modifiedDate: Date()
        )
    }

    private func ayah(_ ayah: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: ayah)!
    }
}
#endif
