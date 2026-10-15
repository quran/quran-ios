import QuranAnnotations
import QuranKit
import XCTest
@testable import NoorUI

final class EditableNoteTests: XCTestCase {
    func test_wordCount_countsLocalizedWordsAndUpdatesWithNote() {
        let sut = makeEditableNote(note: "Reflect deeply.\nتدبّر جيدًا")

        XCTAssertEqual(sut.wordCount, 4)

        sut.note = "One"

        XCTAssertEqual(sut.wordCount, 1)
    }

    func test_updateReading_updatesReading() {
        let sut = makeEditableNote(note: "Note")

        sut.updateReading(.indoPak)

        XCTAssertEqual(sut.reading, .indoPak)
    }

    func test_metadataAccessibilityLabel_separatesEditedDateAndWordCountWithTheListSeparator() {
        let sut = makeEditableNote(note: "Reflect deeply", editedSince: "Monday, October 14, 2026")

        XCTAssertEqual(sut.metadataAccessibilityLabel, "Edited Monday, October 14, 2026; 2 words")
    }

    func test_metadataAccessibilityLabel_withoutEditedDate_isWordCount() {
        let sut = makeEditableNote(note: "Reflect deeply", editedSince: "")

        XCTAssertEqual(sut.metadataAccessibilityLabel, "2 words")
    }

    private func makeEditableNote(note: String, editedSince: String = "2 hours ago") -> EditableNote {
        let ayah = Quran.hafsMadani1405.suras[0].verses[0]
        return EditableNote(
            ayahRanges: [ayah ... ayah],
            ayahText: "بِسْمِ اللَّهِ",
            reading: .hafs_1405,
            editedSince: editedSince,
            selectedColor: .blue,
            note: note
        )
    }
}
