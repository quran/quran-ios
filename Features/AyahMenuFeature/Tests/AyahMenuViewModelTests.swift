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

    func test_readingBookmarkState_disablesSelectionForMultipleAyahs() {
        let sut = makeSUT()

        XCTAssertEqual(
            sut.readingBookmarkState,
            .disabled(message: l("ayah.menu.reading-bookmark.single-ayah-only"))
        )
        XCTAssertNil(sut.selectedAyah)
    }

    func test_readingBookmarkState_isAvailableWithoutSelectionForSingleAyah() {
        let selectedAyah = verses[0]
        let sut = makeSUT(verses: [selectedAyah])

        XCTAssertEqual(sut.readingBookmarkState, .available(slot: nil))
        XCTAssertEqual(sut.selectedAyah, selectedAyah)
    }

    func test_readingBookmarkState_showsSelectedSlotForSingleAyah() {
        let selectedAyah = verses[0]
        let sut = makeSUT(
            verses: [selectedAyah],
            readingBookmark: readingBookmark(slot: .indigo, at: selectedAyah)
        )

        XCTAssertEqual(sut.readingBookmarkState, .available(slot: .indigo))
    }

    func test_editNote_requestsNotesListAndNewNoteWhenSelectionHasNoNotes() async {
        let sut = makeSUT()
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.editNote()

        XCTAssertEqual(listener.shownNoteVerses, verses)
        XCTAssertTrue(listener.isAddingNewNote)
    }

    func test_editNote_requestsOnlyNotesListWhenSelectionHasNotes() async {
        let sut = makeSUT(notes: [note(id: "note")])
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.editNote()

        XCTAssertEqual(listener.shownNoteVerses, verses)
        XCTAssertFalse(listener.isAddingNewNote)
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

    private func readingBookmark(
        slot: ReadingBookmarkSlot,
        at ayah: AyahNumber
    ) -> ReadingPositionBookmark {
        ReadingPositionBookmark(
            id: "reading-bookmark",
            slot: slot,
            location: .ayah(ayah),
            modifiedOn: .distantPast
        )
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
    private(set) var shownNoteVerses: [AyahNumber]?
    private(set) var isAddingNewNote = false

    func dismissAyahMenu() {}
    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {}
    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {}
    func showTranslation(_ verses: [AyahNumber]) {}
    func deleteNotes(in verses: [AyahNumber]) async {}

    func showNotes(for verses: [AyahNumber], addingNewNote: Bool) async {
        shownNoteVerses = verses
        isAddingNewNote = addingNewNote
    }

    func showCollectionEditor(for verses: [AyahNumber]) {
        bookmarkedVerses = verses
    }

    func showReadingBookmarkMenu(_ viewController: UIViewController, in sourceView: UIView, at point: CGPoint) {}
}
#endif
