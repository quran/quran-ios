#if QURAN_SYNC
import AnnotationsService
import Localization
import NoorUI
import QuranAnnotations
import QuranAudioKit
import QuranKit
import QuranResources
import QuranTextKit
import UIKit
import XCTest
@testable import AyahMenuFeature

@MainActor
final class AyahMenuViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        resetReadingBookmarkNewBadge()
    }

    override func tearDown() {
        resetReadingBookmarkNewBadge()
        super.tearDown()
    }

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
        let sut = makeSUT(highlightVerses: [verses[0]: .pink])

        XCTAssertEqual(sut.bookmarkState, .partiallyHighlighted)
    }

    func test_bookmarkState_isPartialWhenSelectedAyahsHaveDifferentHighlightColors() {
        let sut = makeSUT(highlightVerses: [verses[0]: .pink, verses[1]: .green])

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

    func test_readingBookmarkState_offersSetHereWithNewBadgeWhenNoBookmarkIsPlaced() {
        let selectedAyah = verses[0]
        let sut = makeSUT(verses: [selectedAyah])

        XCTAssertEqual(
            sut.readingBookmarkState,
            .available(bookmark: nil, subtitle: l("bookmarks.reading.set-here"), showsNewBadge: true)
        )
    }

    func test_readingBookmarkState_showsSelectedBookmarkForSingleAyah() {
        let selectedAyah = verses[0]
        let bookmark = readingBookmark(slot: .red, at: selectedAyah)
        let sut = makeSUT(
            verses: [selectedAyah],
            readingBookmark: bookmark,
            placedReadingBookmarks: [bookmark]
        )

        XCTAssertEqual(
            sut.readingBookmarkState,
            .available(bookmark: bookmark, subtitle: bookmark.displayName, showsNewBadge: false)
        )
    }

    func test_readingBookmarkState_offersMoveHereWhenABookmarkIsPlacedElsewhere() {
        let elsewhere = readingBookmark(slot: .teal, at: verses[1])
        let sut = makeSUT(verses: [verses[0]], placedReadingBookmarks: [elsewhere])

        XCTAssertEqual(
            sut.readingBookmarkState,
            .available(bookmark: nil, subtitle: l("bookmarks.reading.move-here"), showsNewBadge: false)
        )
    }

    func test_readingBookmarkState_hidesNewBadgeAndOffersMoveHereWhileBookmarksAreLoading() {
        let sut = makeSUT(verses: [verses[0]], placedReadingBookmarks: nil)

        XCTAssertEqual(
            sut.readingBookmarkState,
            .available(bookmark: nil, subtitle: l("bookmarks.reading.move-here"), showsNewBadge: false)
        )
        XCTAssertEqual(AyahMenuPreferences.shared.readingBookmarkNewBadgeViews, 0)
        XCTAssertFalse(AyahMenuPreferences.shared.isReadingBookmarkNewBadgeRetired)
    }

    func test_newBadge_multiAyahMenusDoNotUseUpViews() {
        for _ in 0 ..< 5 {
            _ = makeSUT().readingBookmarkState
        }

        XCTAssertTrue(showsNewBadge(makeSUT(verses: [verses[0]])))
    }

    func test_newBadge_staysRetiredOnceAnyMenuSeesAPlacedBookmark() {
        let elsewhere = readingBookmark(slot: .teal, at: verses[1])
        _ = makeSUT(placedReadingBookmarks: [elsewhere]).readingBookmarkState

        XCTAssertFalse(showsNewBadge(makeSUT(verses: [verses[0]])))
    }

    func test_newBadge_retiresAfterFiveViews() {
        for _ in 0 ..< 5 {
            XCTAssertTrue(showsNewBadge(makeSUT(verses: [verses[0]])))
        }

        XCTAssertFalse(showsNewBadge(makeSUT(verses: [verses[0]])))
    }

    func test_showReadingBookmarkMenu_forwardsSingleSelectedAyah() {
        let selectedAyah = verses[0]
        let sut = makeSUT(verses: [selectedAyah])
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        sut.showReadingBookmarkMenu()

        XCTAssertEqual(listener.readingBookmarkMenuAyah, selectedAyah)
    }

    func test_showReadingBookmarkMenu_forwardsNothingForMultipleAyahs() {
        let sut = makeSUT()
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        sut.showReadingBookmarkMenu()

        XCTAssertNil(listener.readingBookmarkMenuAyah)
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

    func test_playSubtitle_followsSavedQuarterAndHizb() {
        let originalAudioEnd = AudioPreferences.shared.audioEnd
        defer { AudioPreferences.shared.audioEnd = originalAudioEnd }
        let sut = makeSUT(verses: [verses[0]])

        AudioPreferences.shared.audioEnd = .quarter
        XCTAssertEqual(sut.playSubtitle, l("ayah.menu.play-end-quarter"))

        AudioPreferences.shared.audioEnd = .hizb
        XCTAssertEqual(sut.playSubtitle, l("ayah.menu.play-end-hizb"))
    }

    func test_share_sharesSelectedVerseText() async throws {
        let originalQuranMode = QuranContentStatePreferences.shared.quranMode
        defer { QuranContentStatePreferences.shared.quranMode = originalQuranMode }
        QuranContentStatePreferences.shared.quranMode = .arabic
        let sut = makeSUT(verses: [AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!], textRetriever: availableTextRetriever)
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.share()

        let sharedText = try XCTUnwrap(listener.sharedLines?.first)
        XCTAssertEqual(listener.sharedLines?.count, 1)
        XCTAssertTrue(sharedText.contains("﴿ ١ ﴾"))
        XCTAssertTrue(sharedText.hasSuffix("\n\nAl-Fātihah, Ayah 1"))
        XCTAssertTrue(listener.shownErrors.isEmpty)
    }

    func test_share_showsErrorWhenVerseTextIsUnavailable() async {
        let sut = makeSUT()
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.share()

        XCTAssertEqual(listener.shownErrors.count, 1)
        XCTAssertNil(listener.sharedLines)
    }

    func test_copy_showsErrorWhenVerseTextIsUnavailable() async {
        let sut = makeSUT()
        let listener = BookmarkListenerSpy()
        sut.listener = listener

        await sut.copy()

        XCTAssertEqual(listener.shownErrors.count, 1)
        // `showError` dismisses the menu itself; dismissing it first would leave that dismissal in flight.
        XCTAssertFalse(listener.didDismiss)
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
        readingBookmark: PlacedReadingBookmark? = nil,
        placedReadingBookmarks: [PlacedReadingBookmark]? = [],
        textRetriever: ShareableVerseTextRetriever? = nil
    ) -> AyahMenuViewModel {
        AyahMenuViewModel(deps: .init(
            sourceView: UIView(),
            pointInView: .zero,
            verses: verses ?? self.verses,
            textRetriever: textRetriever ?? unavailableTextRetriever,
            notes: notes,
            highlightVerses: highlightVerses,
            bookmarkedVerses: bookmarkedVerses,
            readingBookmark: readingBookmark,
            placedReadingBookmarks: placedReadingBookmarks
        ))
    }

    private func showsNewBadge(_ sut: AyahMenuViewModel) -> Bool {
        guard case .available(_, _, let showsNewBadge) = sut.readingBookmarkState else {
            return false
        }
        return showsNewBadge
    }

    private func resetReadingBookmarkNewBadge() {
        AyahMenuPreferences.shared.readingBookmarkNewBadgeViews = 0
        AyahMenuPreferences.shared.isReadingBookmarkNewBadgeRetired = false
    }

    private var unavailableTextRetriever: ShareableVerseTextRetriever {
        ShareableVerseTextRetriever(databasesURL: unavailableDatabase, quranFileURL: unavailableDatabase)
    }

    private var availableTextRetriever: ShareableVerseTextRetriever {
        ShareableVerseTextRetriever(
            databasesURL: unavailableDatabase,
            quranFileURL: QuranResources.quranUthmaniV2Database
        )
    }

    private var unavailableDatabase: URL {
        URL(fileURLWithPath: "/tmp/unavailable-quran-database")
    }

    private func readingBookmark(
        slot: ReadingBookmarkSlot,
        at ayah: AyahNumber
    ) -> PlacedReadingBookmark {
        PlacedReadingBookmark(
            id: "reading-bookmark",
            slot: slot,
            placement: .ayah(ayah),
            modifiedOn: .distantPast
        )
    }

    private func note(id: String) -> Note {
        Note(
            id: id,
            text: "Note",
            verses: [verses[0]],
            modifiedDate: .distantPast
        )
    }
}

@MainActor
private final class BookmarkListenerSpy: AyahMenuListener {
    private(set) var bookmarkedVerses: [AyahNumber]?
    private(set) var shownNoteVerses: [AyahNumber]?
    private(set) var isAddingNewNote = false
    private(set) var didDismiss = false
    private(set) var sharedLines: [String]?
    private(set) var shownErrors: [Error] = []
    private(set) var readingBookmarkMenuAyah: AyahNumber?

    func dismissAyahMenu() {
        didDismiss = true
    }

    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {}

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {
        sharedLines = lines
    }

    func showError(_ error: Error) {
        shownErrors.append(error)
    }

    func showTranslation(_ verses: [AyahNumber]) {}
    func deleteNotes(in verses: [AyahNumber]) async {}

    func showNotes(for verses: [AyahNumber], addingNewNote: Bool) async {
        shownNoteVerses = verses
        isAddingNewNote = addingNewNote
    }

    func showCollectionEditor(for verses: [AyahNumber]) {
        bookmarkedVerses = verses
    }

    func showReadingBookmarkMenu(for ayah: AyahNumber, in sourceView: UIView, at point: CGPoint) {
        readingBookmarkMenuAyah = ayah
    }
}
#endif
