#if QURAN_SYNC
import MobileSync
import QuranKit
import XCTest
@testable import AnnotationsService

final class MobileSyncNoteServiceTests: XCTestCase {
    func test_notes_mapsContinuousRange() {
        let notes = MobileSyncNoteService.notes(from: [
            Note_(
                body: "Remember this",
                startSura: 1,
                startAyah: 1,
                endSura: 1,
                endAyah: 2,
                lastUpdated: .distantPast,
                localId: "note-1"
            ),
        ], quran: .hafsMadani1405)

        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes[0].localId, "note-1")
        XCTAssertEqual(notes[0].body, "Remember this")
        XCTAssertEqual(notes[0].startAyah, AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1))
        XCTAssertEqual(notes[0].endAyah, AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2))
    }

    func test_notes_keepsMultipleNotesForSameAyah() {
        let notes = MobileSyncNoteService.notes(from: [
            Self.note(localId: "note-1", body: "First"),
            Self.note(localId: "note-2", body: "Second"),
        ], quran: .hafsMadani1405)

        XCTAssertEqual(Set(notes.map { note in note.localId }), ["note-1", "note-2"])
    }

    func test_notes_sortsByLatestUpdatedDate() {
        let notes = MobileSyncNoteService.notes(from: [
            Self.note(localId: "older", body: "Older", lastUpdated: Date(timeIntervalSince1970: 1)),
            Self.note(localId: "newer", body: "Newer", lastUpdated: Date(timeIntervalSince1970: 2)),
        ], quran: .hafsMadani1405)

        XCTAssertEqual(notes.map(\.localId), ["newer", "older"])
    }

    private static func note(localId: String, body: String, lastUpdated: Date = .distantPast) -> Note_ {
        Note_(
            body: body,
            startSura: 1,
            startAyah: 1,
            endSura: 1,
            endAyah: 1,
            lastUpdated: lastUpdated,
            localId: localId
        )
    }
}
#endif
