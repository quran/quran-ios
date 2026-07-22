#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest
@testable import NoorUI
@testable import QuranViewFeature

final class ReadingBookmarkUndoToastTests: XCTestCase {
    func test_saved_describesLocationWithoutAction() {
        let bookmark = bookmark(at: .ayah(ayah(255)))

        let toast = ReadingBookmarkUndoToast.saved(bookmark)

        XCTAssertEqual(
            toast.message.rawValue(locale: Locale(identifier: "en")),
            "Reading bookmark saved at Al-Baqarah \u{E905} · 2:255"
        )
        XCTAssertNil(toast.action)
    }

    func test_savedPage_describesPageWithoutAction() {
        let bookmark = bookmark(at: .page(ayah(255).page))

        let toast = ReadingBookmarkUndoToast.saved(bookmark)

        XCTAssertEqual(toast.message.rawValue(locale: Locale(identifier: "en")), "Reading bookmark saved at Page 42")
        XCTAssertNil(toast.action)
    }

    func test_moved_describesBothLocationsAndProvidesUndo() {
        let previousBookmark = bookmark(at: .page(ayah(255).page))
        let currentBookmark = bookmark(at: .ayah(ayah(255)))
        var didUndo = false

        let toast = ReadingBookmarkUndoToast.moved(from: previousBookmark, to: currentBookmark) {
            didUndo = true
        }

        XCTAssertEqual(
            toast.message.rawValue(locale: Locale(identifier: "en")),
            "Reading bookmark moved from Page 42 to Al-Baqarah \u{E905} · 2:255"
        )
        XCTAssertEqual(toast.action?.title, "Undo")
        toast.action?.handler()
        XCTAssertTrue(didUndo)
    }

    func test_removed_describesLocationAndProvidesUndo() {
        let bookmark = bookmark(at: .ayah(ayah(255)))
        var didUndo = false

        let toast = ReadingBookmarkUndoToast.removed(bookmark) {
            didUndo = true
        }

        XCTAssertEqual(
            toast.message.rawValue(locale: Locale(identifier: "en")),
            "Reading bookmark removed from Al-Baqarah \u{E905} · 2:255"
        )
        XCTAssertEqual(toast.action?.title, "Undo")
        toast.action?.handler()
        XCTAssertTrue(didUndo)
    }

    func test_removedPage_describesPageAndProvidesUndo() {
        let bookmark = bookmark(at: .page(ayah(255).page))
        var didUndo = false

        let toast = ReadingBookmarkUndoToast.removed(bookmark) {
            didUndo = true
        }

        XCTAssertEqual(toast.message.rawValue(locale: Locale(identifier: "en")), "Reading bookmark removed from Page 42")
        XCTAssertEqual(toast.action?.title, "Undo")
        toast.action?.handler()
        XCTAssertTrue(didUndo)
    }

    private func bookmark(at location: ReadingPositionBookmark.Location) -> ReadingPositionBookmark {
        ReadingPositionBookmark(id: "reading-bookmark", location: location, modifiedOn: .distantPast)
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: number)!
    }
}
#endif
