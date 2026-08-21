import Combine
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

    func test_quranFont_updatesFromSource() {
        let updates = PassthroughSubject<QuranFont, Never>()
        let sut = makeEditableNote(
            note: "Note",
            quranFontSource: QuranFontSource(current: { .uthmanicHafs }, updates: updates)
        )

        updates.send(.indoPak)

        XCTAssertEqual(sut.quranFont, .indoPak)
    }

    private func makeEditableNote(
        note: String,
        quranFontSource: QuranFontSource = QuranFontSource(.uthmanicHafs)
    ) -> EditableNote {
        let ayah = Quran.hafsMadani1405.suras[0].verses[0]
        return EditableNote(
            ayahRange: ayah ... ayah,
            ayahText: "بِسْمِ اللَّهِ",
            quranFontSource: quranFontSource,
            modifiedSince: "2 hours ago",
            selectedColor: .blue,
            note: note
        )
    }
}
