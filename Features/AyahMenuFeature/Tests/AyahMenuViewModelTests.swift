#if QURAN_SYNC
import Localization
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit
import XCTest
@testable import AyahMenuFeature

@MainActor
final class AyahMenuViewModelTests: XCTestCase {
    func test_bookmark_requestsEditorForCrossSuraSelection() {
        let sut = makeSUT()
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        sut.bookmark()

        XCTAssertEqual(listener.bookmarkedVerses, verses)
    }

    func test_bookmarkState_isUnhighlightedWhenNoSelectedAyahIsHighlighted() {
        let sut = makeSUT()

        XCTAssertEqual(sut.bookmarkState, .unhighlighted)
    }

    func test_bookmarkState_isBookmarkedWhenAnySelectedAyahBelongsToACollection() {
        let sut = makeSUT(bookmarkedVerses: [verses[0]])

        XCTAssertEqual(sut.bookmarkState, .bookmarked)
    }

    func test_bookmarkState_isUnhighlightedWhenOnlyUnselectedAyahsBelongToACollection() {
        let otherVerse = AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 2)!
        let sut = makeSUT(bookmarkedVerses: [otherVerse])

        XCTAssertEqual(sut.bookmarkState, .unhighlighted)
    }

    func test_bookmarkState_usesHighlightColorWhenEverySelectedAyahHasTheSameColor() {
        let sut = makeSUT(highlightVerses: Dictionary(uniqueKeysWithValues: verses.map { ($0, .green) }))

        XCTAssertEqual(sut.bookmarkState, .highlighted(.green))
    }

    func test_bookmarkState_isPartialWhenOnlySomeSelectedAyahsAreHighlighted() {
        let sut = makeSUT(highlightVerses: [verses[0]: .red])

        XCTAssertEqual(sut.bookmarkState, .partiallyHighlighted)
    }

    func test_bookmarkState_isPartialWhenSelectedAyahsHaveDifferentHighlightColors() {
        let sut = makeSUT(highlightVerses: [verses[0]: .red, verses[1]: .green])

        XCTAssertEqual(sut.bookmarkState, .partiallyHighlighted)
    }

    func test_bookmarkTitle_usesSaveAyahSingularAndPluralCopy() {
        XCTAssertEqual(lFormat("bookmarks.editor.title", language: .english, 1), "Save Ayah...")
        XCTAssertEqual(lFormat("bookmarks.editor.title", language: .english, 2), "Save Ayahs...")
    }

    private var verses: [AyahNumber] {
        [
            AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 7)!,
            AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 1)!,
        ]
    }

    private func makeSUT(
        highlightVerses: [AyahNumber: HighlightColor] = [:],
        bookmarkedVerses: Set<AyahNumber> = []
    ) -> AyahMenuViewModel {
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        return AyahMenuViewModel(deps: .init(
            sourceView: UIView(),
            pointInView: .zero,
            verses: verses,
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            notes: [],
            highlightVerses: highlightVerses,
            bookmarkedVerses: bookmarkedVerses
        ))
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
