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
            XCTAssertEqual(notes[0].verses, [
                AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!,
                AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2)!,
            ])
        }

        func test_notes_keepsMultipleNotesForSameAyah() {
            let notes = MobileSyncNoteService.notes(from: [
                note(localId: "note-1", body: "First"),
                note(localId: "note-2", body: "Second"),
            ], quran: .hafsMadani1405)

            XCTAssertEqual(Set(notes.map(\.localId)), ["note-1", "note-2"])
        }

        private static func note(localId: String, body: String) -> Note_ {
            Note_(
                body: body,
                startSura: 1,
                startAyah: 1,
                endSura: 1,
                endAyah: 1,
                lastUpdated: .distantPast,
                localId: localId
            )
        }
    }
#endif
