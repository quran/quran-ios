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

    private func makeEditableNote(note: String) -> EditableNote {
        let ayah = Quran.hafsMadani1405.suras[0].verses[0]
        return EditableNote(
            ayahRange: ayah ... ayah,
            ayahText: "بِسْمِ اللَّهِ",
            modifiedSince: "2 hours ago",
            selectedColor: .blue,
            note: note
        )
    }
}
