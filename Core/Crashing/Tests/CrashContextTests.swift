import XCTest
@testable import Crashing

final class CrashContextTests: XCTestCase {
    func testListStateRecordsActiveAndLastUpdateContexts() {
        let handler = RecordingCrashInfoHandler()
        let sut = CrashContext(crasher: Crasher(handler: handler))

        sut.setActiveList(owner: "home", mode: "suras", generation: 1, sectionCount: 30, rowCount: 114)
        sut.recordListUpdate(owner: "home", reason: "mode_change", rowsBefore: 240, rowsAfter: 114, generation: 2)

        XCTAssertEqual(handler.value(for: "active_list_owner") as? String, "home")
        XCTAssertEqual(handler.value(for: "active_list_row_count") as? Int, 114)
        XCTAssertEqual(handler.value(for: "last_list_update_reason") as? String, "mode_change")
        XCTAssertEqual(handler.value(for: "last_list_rows_before") as? Int, 240)
        XCTAssertEqual(handler.value(for: "last_list_rows_after") as? Int, 114)
    }

    func testClearingStaleListOwnerDoesNotClearNewOwner() {
        let handler = RecordingCrashInfoHandler()
        let sut = CrashContext(crasher: Crasher(handler: handler))
        sut.setActiveList(owner: "home", mode: "suras", generation: 1, sectionCount: 30, rowCount: 114)
        sut.setActiveList(owner: "settings", mode: "root", generation: 1, sectionCount: 5, rowCount: 20)

        sut.clearActiveList(owner: "home")

        XCTAssertEqual(handler.value(for: "active_list_owner") as? String, "settings")
        XCTAssertEqual(handler.value(for: "active_list_row_count") as? Int, 20)
    }

    func testDuplicateValuesAreNotWrittenAgain() {
        let handler = RecordingCrashInfoHandler()
        let sut = CrashContext(crasher: Crasher(handler: handler))

        sut.setApplicationState("active")
        sut.setApplicationState("active")

        XCTAssertEqual(handler.writeCount(for: "app_state"), 1)
    }

    func testClearingStalePresentationOwnerDoesNotClearNewPresentation() {
        let handler = RecordingCrashInfoHandler()
        let sut = CrashContext(crasher: Crasher(handler: handler))
        sut.setPresentation(owner: "reciter_list", kind: "sheet", phase: "presented", interactive: false)
        sut.setPresentation(owner: "advanced_audio_options", kind: "sheet", phase: "presenting", interactive: false)

        sut.clearPresentation(owner: "reciter_list")

        XCTAssertEqual(handler.value(for: "presentation_owner") as? String, "advanced_audio_options")
        XCTAssertEqual(handler.value(for: "presentation_phase") as? String, "presenting")
    }

    func testAudioContextUsesPrimitiveValuesAndExplicitEmptyState() {
        let handler = RecordingCrashInfoHandler()
        let sut = CrashContext(crasher: Crasher(handler: handler))

        sut.setAudioReciter(id: 7)
        sut.setPlayingAyah(sura: 2, ayah: 255)

        XCTAssertEqual(handler.value(for: "audio_reciter_id") as? String, "7")
        XCTAssertEqual(handler.value(for: "audio_playing_sura") as? Int, 2)
        XCTAssertEqual(handler.value(for: "audio_playing_ayah") as? Int, 255)

        sut.clearPlayingAyah()
        sut.setAudioReciter(id: nil)

        XCTAssertEqual(handler.value(for: "audio_reciter_id") as? String, "none")
        XCTAssertEqual(handler.value(for: "audio_playing_sura") as? Int, 0)
        XCTAssertEqual(handler.value(for: "audio_playing_ayah") as? Int, 0)
    }

    func testVisiblePageContextRecordsNormalizedRangeAndCount() {
        let handler = RecordingCrashInfoHandler()
        let sut = CrashContext(crasher: Crasher(handler: handler))

        sut.setVisiblePages([46, 45])

        XCTAssertEqual(handler.value(for: "quran_visible_page_minimum") as? Int, 45)
        XCTAssertEqual(handler.value(for: "quran_visible_page_maximum") as? Int, 46)
        XCTAssertEqual(handler.value(for: "quran_visible_page_count") as? Int, 2)

        sut.setVisiblePages([])

        XCTAssertEqual(handler.value(for: "quran_visible_page_minimum") as? Int, 0)
        XCTAssertEqual(handler.value(for: "quran_visible_page_maximum") as? Int, 0)
        XCTAssertEqual(handler.value(for: "quran_visible_page_count") as? Int, 0)
    }
}

private final class RecordingCrashInfoHandler: CrashInfoHandler {
    private var values: [String: Any] = [:]
    private var writes: [String: Int] = [:]

    func setCustomValue(_ value: Any, forKey key: String) {
        values[key] = value
        writes[key, default: 0] += 1
    }

    func recordError(_ error: Error, reason: String, file: StaticString, line: UInt) {
    }

    func value(for key: String) -> Any? {
        values[key]
    }

    func writeCount(for key: String) -> Int {
        writes[key, default: 0]
    }
}
