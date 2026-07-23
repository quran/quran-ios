#if QURAN_SYNC
import AnnotationsService
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

    func test_notesTitle_showsLocalizedNumberOfNotes() {
        let sut = makeSUT(notes: [
            note(id: "first"),
            note(id: "second"),
        ])

        XCTAssertEqual(sut.notesTitle, lFormat("ayah.menu.notes-count", 2))
        XCTAssertEqual(lFormat("ayah.menu.notes-count", language: .english, 2), "Notes (2)")
        XCTAssertEqual(lFormat("ayah.menu.notes-count", language: .arabic, 2), "الملاحظات (2)")
    }

    func test_readingBookmarkCopy_describesEachLocationState() {
        XCTAssertEqual(l("ayah.menu.reading-bookmark.save-here"), "Save your place here")
        XCTAssertEqual(l("ayah.menu.reading-bookmark.saved-here"), "Saved here • Tap to delete")
        XCTAssertEqual(
            lFormat("ayah.menu.reading-bookmark.move-here", "Al-Baqarah 2:255"),
            "At Al-Baqarah 2:255 • Move here"
        )
    }

    func test_readingBookmarkState_isDisabledForMultipleSelectedAyahs() {
        let sut = makeSUT()

        guard case .disabled(let message) = sut.readingBookmarkState else {
            return XCTFail("Expected disabled reading bookmark state")
        }
        XCTAssertEqual(message, l("ayah.menu.reading-bookmark.single-ayah-only"))
    }

    func test_readingBookmarkState_isUnsetWhenNoReadingBookmarkExists() {
        let sut = makeSUT(verses: [verses[0]])

        guard case .unset = sut.readingBookmarkState else {
            return XCTFail("Expected unset reading bookmark state")
        }
    }

    func test_readingBookmarkState_isCurrentForSelectedAyah() {
        let selected = verses[0]
        let sut = makeSUT(
            verses: [selected],
            readingBookmark: readingBookmark(at: .ayah(selected))
        )

        guard case .current = sut.readingBookmarkState else {
            return XCTFail("Expected current reading bookmark state")
        }
    }

    func test_readingBookmarkState_isElsewhereForPageContainingSelectedAyah() {
        let selected = verses[0]
        let sut = makeSUT(
            verses: [selected],
            readingBookmark: readingBookmark(at: .page(selected.page))
        )

        guard case .elsewhere = sut.readingBookmarkState else {
            return XCTFail("Expected elsewhere reading bookmark state")
        }
    }

    func test_readingBookmarkState_isElsewhereForDifferentAyah() {
        let sut = makeSUT(
            verses: [verses[0]],
            readingBookmark: readingBookmark(at: .ayah(verses[1]))
        )

        guard case .elsewhere = sut.readingBookmarkState else {
            return XCTFail("Expected elsewhere reading bookmark state")
        }
    }

    func test_setReadingBookmark_requestsSetWithoutPreviousBookmark() async {
        let selected = verses[0]
        let sut = makeSUT(verses: [selected])
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.setReadingBookmark()

        XCTAssertEqual(listener.readingBookmarkSet?.ayah, selected)
        XCTAssertNil(listener.readingBookmarkSet?.replacedBookmark)
    }

    func test_setReadingBookmark_requestsReplacementOfPreviousBookmark() async {
        let selected = verses[0]
        let previousBookmark = readingBookmark(at: .ayah(verses[1]))
        let sut = makeSUT(verses: [selected], readingBookmark: previousBookmark)
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.setReadingBookmark()

        XCTAssertEqual(listener.readingBookmarkSet?.ayah, selected)
        XCTAssertEqual(listener.readingBookmarkSet?.replacedBookmark, previousBookmark)
    }

    func test_removeReadingBookmark_requestsRemovalOfCurrentBookmark() async {
        let selected = verses[0]
        let bookmark = readingBookmark(at: .ayah(selected))
        let sut = makeSUT(verses: [selected], readingBookmark: bookmark)
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.removeReadingBookmark()

        XCTAssertEqual(listener.removedReadingBookmark, bookmark)
    }

    func test_removeReadingBookmark_doesNotRemovePageBookmarkContainingSelectedAyah() async {
        let selected = verses[0]
        let bookmark = readingBookmark(at: .page(selected.page))
        let sut = makeSUT(verses: [selected], readingBookmark: bookmark)
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.removeReadingBookmark()

        XCTAssertNil(listener.removedReadingBookmark)
    }

    private var verses: [AyahNumber] {
        [
            AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 7)!,
            AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 1)!,
        ]
    }

    private func makeSUT(
        verses: [AyahNumber]? = nil,
        notes: [Note] = [],
        highlightVerses: [AyahNumber: HighlightColor] = [:],
        bookmarkedVerses: Set<AyahNumber> = [],
        readingBookmark: ReadingPositionBookmark? = nil
    ) -> AyahMenuViewModel {
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        return AyahMenuViewModel(deps: .init(
            sourceView: UIView(),
            pointInView: .zero,
            verses: verses ?? self.verses,
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            notes: notes,
            highlightVerses: highlightVerses,
            bookmarkedVerses: bookmarkedVerses,
            readingBookmark: readingBookmark
        ))
    }

    private func readingBookmark(at location: ReadingPositionBookmark.Location) -> ReadingPositionBookmark {
        ReadingPositionBookmark(id: "reading-bookmark", location: location, modifiedOn: .distantPast)
    }

    private func note(id: String) -> Note {
        Note(
            id: id,
            text: "Note",
            startAyah: verses[0],
            endAyah: verses[0],
            modifiedDate: .distantPast
        )
    }
}

@MainActor
private final class BookmarkListenerSpy: AyahMenuListener {
    private(set) var bookmarkedVerses: [AyahNumber]?
    private(set) var readingBookmarkSet: (ayah: AyahNumber, replacedBookmark: ReadingPositionBookmark?)?
    private(set) var removedReadingBookmark: ReadingPositionBookmark?

    func dismissAyahMenu() {}
    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {}
    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {}
    func showTranslation(_ verses: [AyahNumber]) {}
    func showNoteEditor(for verses: [AyahNumber]) async {}
    func deleteNotes(in verses: [AyahNumber]) async {}

    func setReadingBookmark(at ayah: AyahNumber, replacing bookmark: ReadingPositionBookmark?) async {
        readingBookmarkSet = (ayah, bookmark)
    }

    func removeReadingBookmark(_ bookmark: ReadingPositionBookmark) async {
        removedReadingBookmark = bookmark
    }

    func showCollectionEditor(for verses: [AyahNumber]) {
        bookmarkedVerses = verses
    }
}
#endif
