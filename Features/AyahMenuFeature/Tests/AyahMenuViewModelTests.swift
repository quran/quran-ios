#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit
import XCTest
@testable import AyahMenuFeature

@MainActor
final class AyahMenuViewModelTests: XCTestCase {
    func test_bookmark_requestsEditorForCrossSuraSelection() throws {
        let verses = [
            try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 7)),
            try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 1)),
        ]
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let sut = AyahMenuViewModel(deps: .init(
            sourceView: UIView(),
            pointInView: .zero,
            verses: verses,
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            notes: []
        ))
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        sut.bookmark()

        XCTAssertEqual(listener.bookmarkedVerses, verses)
    }
}

@MainActor
private final class BookmarkListenerSpy: AyahMenuListener {
    private(set) var bookmarkedVerses: [AyahNumber]?

    func dismissAyahMenu() {}
    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {}
    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {}
    func showTranslation(_ verses: [AyahNumber]) {}
    func showNoteEditor(for verses: [AyahNumber]) async {}
    func deleteNotes(in verses: [AyahNumber]) async {}

    func showBookmarkEditor(for verses: [AyahNumber]) {
        bookmarkedVerses = verses
    }
}
#endif
