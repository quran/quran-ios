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

    private func makeEditableNote(note: String) -> EditableNote {
        let ayah = Quran.hafsMadani1405.suras[0].verses[0]
        return EditableNote(
            ayahRange: ayah ... ayah,
            ayahText: "بِسْمِ اللَّهِ",
            reading: .hafs_1405,
            modifiedSince: "2 hours ago",
            selectedColor: .blue,
            note: note
        )
    }
}
