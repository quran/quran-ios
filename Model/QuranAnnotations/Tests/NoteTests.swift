#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import XCTest

final class NoteTests: XCTestCase {
    func test_noteOnSeveralRanges_spansItsVersesAndIntersectsOnlyThem() {
        let note = Note(
            id: "1",
            text: "On two passages",
            verses: [verse(2, 255), verse(2, 256), verse(3, 18)],
            modifiedDate: Date(timeIntervalSince1970: 1)
        )

        XCTAssertEqual(note.startAyah, verse(2, 255))
        XCTAssertEqual(note.endAyah, verse(3, 18))
        XCTAssertTrue(note.intersects(verses: [verse(3, 18)]))
        XCTAssertFalse(note.intersects(verses: [verse(2, 257), verse(3, 17)]))
    }

    private func verse(_ sura: Int, _ ayah: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: sura, ayah: ayah)!
    }
}
#endif
