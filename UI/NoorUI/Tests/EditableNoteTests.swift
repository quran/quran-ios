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

    func test_metadataAccessibilityLabel_separatesCreatedDateAndWordCountWithTheListSeparator() {
        let sut = makeEditableNote(note: "Reflect deeply", modifiedSince: "Monday, October 14, 2026")

        XCTAssertEqual(sut.metadataAccessibilityLabel, "Created Monday, October 14, 2026; 2 words")
    }

    func test_metadataAccessibilityLabel_withoutCreatedDate_isWordCount() {
        let sut = makeEditableNote(note: "Reflect deeply", modifiedSince: "")

        XCTAssertEqual(sut.metadataAccessibilityLabel, "2 words")
    }

    private func makeEditableNote(note: String, modifiedSince: String = "2 hours ago") -> EditableNote {
        let ayah = Quran.hafsMadani1405.suras[0].verses[0]
        return EditableNote(
            ayahRanges: [ayah ... ayah],
            ayahText: "بِسْمِ اللَّهِ",
            reading: .hafs_1405,
            modifiedSince: modifiedSince,
            selectedColor: .blue,
            note: note
        )
    }
}
