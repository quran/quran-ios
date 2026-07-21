//
//  QuranInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Analytics
import AnnotationsService
import AudioBannerFeature
import AyahMenuFeature
import BookmarksFeature
import Combine
import Crashing
import FeaturesSupport
import MoreMenuFeature
import NoorUI
import NoteEditorFeature
import QuranAnnotations
import QuranContentFeature
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import TranslationService
import TranslationsFeature
import TranslationVerseFeature
import UIKit
import UIx
import VLogging
import WordPointerFeature

@MainActor
protocol QuranPresentable: UIViewController {
    var pagesView: UIView { get }

    func startHiddenBarsTimer()
    func hideBars()

    func setVisiblePages(_ pages: [Page])
    func updateBookmark(_ isBookmarked: Bool)

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint, completion: @escaping () -> Void)

    func presentMoreMenu(_ viewController: UIViewController)
    func presentAyahMenu(_ viewController: UIViewController, in sourceView: UIView, at point: CGPoint)
    func presentBookmarkAyahs(_ viewController: UIViewController)
    func presentTranslatedVerse(_ viewController: UIViewController, didDismiss: @escaping () -> Void)
    func presentAudioBanner(_ audioBanner: UIViewController)
    func presentWordPointer(_ viewController: UIViewController)
    func presentQuranContent(_ viewController: UIViewController)
    func presentTranslationsSelection(_ viewController: UIViewController)

    func dismissWordPointer(_ viewController: UIViewController)
    func dismissPresentedViewController(completion: (() -> Void)?)
    func showToast(_ toast: Toast)
}

@MainActor
final class QuranInteractor: WordPointerListener, ContentListener, NoteEditorListener,
    MoreMenuListener, AudioBannerListener, AyahMenuListener
{
    struct Deps {
        let quran: Quran
        let highlightsService: QuranHighlightsService
        let ayahMenuBuilder: AyahMenuBuilder
        let bookmarkAyahsBuilder: BookmarkAyahsBuilder
        let moreMenuBuilder: MoreMenuBuilder
        let audioBannerBuilder: AudioBannerBuilder
        let wordPointerBuilder: WordPointerBuilder
        let contentBuilder: ContentBuilder
        let translationsSelectionBuilder: TranslationsListBuilder
        let translationVerseBuilder: TranslationVerseBuilder
        let resources: ReadingResourcesService
        let notesObserver: QuranNotesObserver
        let noteEditorBuilder: NoteEditorBuilder
        #if QURAN_SYNC
        let syncedHighlightsObserver: QuranSyncedHighlightsObserver
        let readingBookmarkObserver: QuranReadingBookmarkObserver
        #else
        let analytics: AnalyticsLibrary
        let pageBookmarkService: PageBookmarkService
        let noteService: NoteService
        #endif
    }

    // MARK: Lifecycle

    init(deps: Deps, input: QuranInput) {
        self.deps = deps
        self.input = input
        logger.info("Quran: opening quran \(input)")
    }

    // MARK: Internal

    @Published var contentStatus: ContentStatusView.State?

    weak var presenter: QuranPresentable?

    // MARK: - Preferences

    var quranMode: QuranMode {
        contentStatePreferences.quranMode
    }

    // MARK: - Audio Banner

    var visiblePages: [Page] { contentViewModel?.visiblePages ?? [] }

    func start() {
        deps.notesObserver.start()
        #if QURAN_SYNC
        deps.syncedHighlightsObserver.start()
        deps.readingBookmarkObserver.$bookmark
            .receive(on: DispatchQueue.main) // sink after the bookmark property is updated
            .sink { [weak self] _ in self?.reloadPageBookmark() }
            .store(in: &cancellables)
        deps.readingBookmarkObserver.start()
        #else
        deps.pageBookmarkService.pageBookmarks(quran: deps.quran)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pageBookmarks = $0 }
            .store(in: &cancellables)
        #endif

        contentStatePreferences.$quranMode
            .sink { [weak self] _ in self?.onQuranModeUpdated() }
            .store(in: &cancellables)

        deps.resources.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .downloading(let progress):
                    self?.contentStatus = .downloading(progress: progress)
                case .error(let error):
                    self?.contentStatus = .error(error, retry: { [weak self] in
                        guard let self else { return }
                        contentStatus = .downloading(progress: 0)
                        Task {
                            await self.deps.resources.retry()
                        }
                    })
                case .ready:
                    self?.contentStatus = nil
                    self?.loadContent()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Popover

    func didDismissPopover() {
        logger.info("Quran: dismiss popover")
        contentViewModel?.removeAyahMenuHighlight()
    }

    // MARK: - More Menu

    func onMoreBarButtonTapped() {
        logger.info("Quran: more bar button tapped")
        var state = MoreMenuControlsState()
        state.wordPointer = readingPreferences.reading.supportsWordPositions ? .conditional : .alwaysOff
        // TODO: Enable vertical scrolling.
        state.verticalScrolling = .alwaysOff
        let model = MoreMenuModel(isWordPointerActive: isWordPointerActive, state: state)
        let viewController = deps.moreMenuBuilder.build(withListener: self, model: model)
        presenter?.presentMoreMenu(viewController)
    }

    func onQuranModeUpdated() {
        let noTranslationsSelected = selectedTranslationsPreferences.selectedTranslationIds.isEmpty
        if quranMode == .translation, noTranslationsSelected {
            presentTranslationsSelection()
        }
    }

    func onTranslationsSelectionsTapped() {
        presentTranslationsSelection()
    }

    func highlightReadingAyah(_ ayah: AyahNumber?) {
        logger.info("Quran: highlight reading verse \(String(describing: ayah))")
        contentViewModel?.highlightReadingAyah(ayah)
    }

    // MARK: - Ayah Menu

    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {
        Task { @MainActor in // TODO: remove
            audioBanner?.play(from: from, to: to, repeatVerses: repeatVerses)
        }
    }

    func deleteNotes(in verses: [AyahNumber]) async {
        #if QURAN_SYNC
        let notesObserver = deps.notesObserver
        let notesToDelete = notesInteractingVerses(verses)
        if !notesToDelete.isEmpty {
            presenter?.confirmNoteDelete(
                delete: { [weak self] in
                    do {
                        self?.contentViewModel?.removeAyahMenuHighlight()
                        for note in notesToDelete {
                            try await notesObserver.remove(note)
                        }
                    } catch {
                        crasher.recordError(error, reason: "Failed to delete synced notes")
                    }
                },
                cancel: { self.contentViewModel?.removeAyahMenuHighlight() }
            )
        }
        #else
        let notes = notesInteractingVerses(verses)
        let containsText = notes.contains { note in
            !(note.text ?? "").isEmpty
        }
        if containsText {
            // confirm deletion first if there is text
            presenter?.confirmNoteDelete(
                delete: { await self.forceDeleteNotes(notes, verses: verses) },
                cancel: { self.contentViewModel?.removeAyahMenuHighlight() }
            )
        } else {
            // delete highlight
            await forceDeleteNotes(notes, verses: verses)
        }
        #endif
    }

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {
        logger.info("Quran: share text")
        dismissAyahMenu()
        presenter?.shareText(lines, in: sourceView, at: point, completion: {})
    }

    func showNoteEditor(for verses: [AyahNumber]) async {
        let notes = notesInteractingVerses(verses)
        #if QURAN_SYNC
        let mode: NoteEditorMode = if let note = notes.first {
            .edit(note)
        } else {
            .create(verses: verses)
        }
        presentNoteEditor(mode: mode)
        #else
        if let note = notes.first {
            presentNoteEditor(note: note)
            return
        }
        do {
            let note = try await deps.notesObserver.prepareNote(for: verses)
            presentNoteEditor(note: note)
        } catch {
            crasher.recordError(error, reason: "Failed to prepare note editor")
        }
        #endif
    }

    func showBookmarkEditor(for verses: [AyahNumber]) {
        logger.info("Quran: show bookmark editor. Verses: \(verses)")
        contentViewModel?.removeAyahMenuHighlight()
        presenter?.dismissPresentedViewController { [weak self] in
            guard let self else {
                return
            }
            #if QURAN_SYNC
            let viewController = deps.bookmarkAyahsBuilder.build(
                verses: verses,
                collections: deps.syncedHighlightsObserver.collections
            )
            #else
            let viewController = deps.bookmarkAyahsBuilder.build(
                verses: verses,
                notes: notesInteractingVerses(verses)
            )
            #endif
            presenter?.presentBookmarkAyahs(viewController)
        }
    }

    #if QURAN_SYNC
    func setReadingBookmark(at ayah: AyahNumber, replacing previousBookmark: ReadingPositionBookmark?) async {
        if await performReadingBookmarkAction(
            .set(location: .ayah(ayah), replacing: previousBookmark)
        ) {
            dismissAyahMenu()
        }
    }

    func removeReadingBookmark(_ bookmark: ReadingPositionBookmark) async {
        if await performReadingBookmarkAction(.remove(bookmark)) {
            dismissAyahMenu()
        }
    }
    #endif

    func dismissNoteEditor() {
        logger.info("Quran: dismiss note editor")
        presenter?.dismiss(animated: true)
    }

    func showTranslation(_ verses: [AyahNumber]) {
        guard let verse = verses.first else {
            return
        }

        let viewController = deps.translationVerseBuilder.build(
            startingVerse: verse,
            actions: .init(updateCurrentVerseTo: { [weak self] verse in
                self?.contentViewModel?.highlightTranslationVerse(verse)
            })
        )
        presenter?.dismissPresentedViewController {
            self.presenter?.presentTranslatedVerse(viewController) { [weak self] in
                self?.contentViewModel?.removeAyahMenuHighlight()
            }
        }
    }

    func presentAyahMenu(in sourceView: UIView, at point: CGPoint, verses: [AyahNumber]) {
        logger.info("Quran: present ayah menu, verses: \(verses)")
        #if QURAN_SYNC
        let highlightVerses = deps.highlightsService.highlights.highlightVerses
        let bookmarkedVerses = Set(deps.syncedHighlightsObserver.collections.flatMap { collection in
            collection.bookmarks.map(\.ayah)
        })
        #else
        let highlightVerses = deps.highlightsService.highlights.noteVerses.mapValues(\.color)
        let bookmarkedVerses: Set<AyahNumber> = []
        #endif
        #if QURAN_SYNC
        let input = AyahMenuInput(
            sourceView: sourceView,
            pointInView: point,
            verses: verses,
            notes: notesInteractingVerses(verses),
            highlightVerses: highlightVerses,
            bookmarkedVerses: bookmarkedVerses,
            readingBookmark: deps.readingBookmarkObserver.bookmark
        )
        #else
        let input = AyahMenuInput(
            sourceView: sourceView,
            pointInView: point,
            verses: verses,
            notes: notesInteractingVerses(verses),
            highlightVerses: highlightVerses,
            bookmarkedVerses: bookmarkedVerses
        )
        #endif
        let ayahMenuViewController = deps.ayahMenuBuilder.build(withListener: self, input: input)
        presenter?.presentAyahMenu(ayahMenuViewController, in: sourceView, at: point)
    }

    func dismissAyahMenu() {
        logger.info("Quran: dismiss ayah menu")
        presenter?.dismissPresentedViewController(completion: nil)
        contentViewModel?.removeAyahMenuHighlight()
    }

    #if QURAN_SYNC
    private func performReadingBookmarkAction(_ action: ReadingBookmarkAction) async -> Bool {
        do {
            switch action {
            case .set(let location, let previousBookmark):
                let bookmark = try await deps.readingBookmarkObserver.add(at: location)
                if let previousBookmark {
                    presenter?.showToast(
                        ReadingBookmarkUndoToast.moved(from: previousBookmark, to: bookmark) { [weak self] in
                            self?.undoReadingBookmarkMove(bookmark, to: previousBookmark)
                        }
                    )
                } else {
                    presenter?.showToast(ReadingBookmarkUndoToast.saved(bookmark))
                }
            case .remove(let bookmark):
                let observer = deps.readingBookmarkObserver
                guard observer.bookmark == bookmark,
                      let removedBookmark = try await observer.remove()
                else {
                    return false
                }
                presenter?.showToast(
                    ReadingBookmarkUndoToast.removed(removedBookmark) { [weak self] in
                        self?.undoReadingBookmarkRemoval(removedBookmark)
                    }
                )
            }
            return true
        } catch {
            crasher.recordError(error, reason: "Failed to update reading bookmark")
            return false
        }
    }

    private func undoReadingBookmarkRemoval(_ deletedBookmark: ReadingPositionBookmark) {
        Task {
            guard deps.readingBookmarkObserver.bookmark == nil else {
                return
            }
            do {
                try await deps.readingBookmarkObserver.add(at: deletedBookmark.location)
            } catch {
                crasher.recordError(error, reason: "Failed to undo reading bookmark removal")
            }
        }
    }

    private func undoReadingBookmarkMove(
        _ movedBookmark: ReadingPositionBookmark,
        to previousBookmark: ReadingPositionBookmark
    ) {
        Task {
            guard deps.readingBookmarkObserver.bookmark == movedBookmark else {
                return
            }
            do {
                try await deps.readingBookmarkObserver.add(at: previousBookmark.location)
            } catch {
                crasher.recordError(error, reason: "Failed to undo reading bookmark move")
            }
        }
    }
    #endif

    // MARK: - Word Pointer

    func onWordPointerPanBegan() {
        presenter?.hideBars()
    }

    func word(at point: CGPoint) -> Word? {
        contentViewController?.word(at: point)
    }

    func highlightWord(_ word: Word?) {
        contentViewModel?.highlightWord(word)
    }

    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool) {
        self.isWordPointerActive = isWordPointerActive
        if isWordPointerActive {
            if let presenter {
                showWordPointer(referenceView: presenter.pagesView)
            }
        } else {
            hideWordPointer()
        }
    }

    func userWillBeginDragScroll() {
        logger.info("Quran: userWillBeginDragScroll")
        presenter?.hideBars()
    }

    func toogleBookmark() async {
        logger.info("Quran: onBookmarkBarButtonTapped")
        #if QURAN_SYNC
        guard let action = ReadingBookmarkAction.page(
            visiblePages: visiblePages,
            bookmark: deps.readingBookmarkObserver.bookmark
        ) else {
            return
        }
        _ = await performReadingBookmarkAction(action)
        #else
        let pages = visiblePages
        let wasBookmarked = bookmarked(pages)

        do {
            let analytics = deps.analytics
            let service = deps.pageBookmarkService
            try await withThrowingTaskGroup(of: Void.self) { group in
                for page in pages {
                    group.addTask {
                        if !wasBookmarked {
                            analytics.bookmarkPage(page)
                            try await service.insertPageBookmark(page)
                        } else {
                            analytics.removeBookmarkPage(page)
                            try await service.removePageBookmark(page)
                        }
                    }
                    try await group.waitForAll()
                }
            }
        } catch {
            crasher.recordError(error, reason: "Failed to toggle page bookmark")
        }
        #endif
    }

    // MARK: Private

    private let readingPreferences = ReadingPreferences.shared
    private let contentStatePreferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    private var deps: Deps
    private let input: QuranInput
    private var audioBanner: AudioBannerViewModel?
    private var cancellables: Set<AnyCancellable> = []
    private var isWordPointerActive: Bool = false
    private var wordPointer: WordPointerViewController?

    private var visiblePageCancellable: AnyCancellable?

    private var contentViewController: ContentViewController?

    private var contentViewModel: ContentViewModel? {
        didSet {
            visiblePageCancellable = contentViewModel?.$visiblePages
                .sink { [weak self] in self?.setVisiblePages($0) }
        }
    }

    #if !QURAN_SYNC
    private var pageBookmarks: [PageBookmark] = [] {
        didSet {
            reloadPageBookmark()
        }
    }
    #endif

    private func setVisiblePages(_ pages: [Page]) {
        logger.info("Quran: set visible pages \(pages)")
        presenter?.setVisiblePages(pages)
        showPageBookmarkIfNeeded(for: pages)
    }

    private func loadContent() {
        let (viewController, viewModel) = deps.audioBannerBuilder.build(withListener: self)
        audioBanner = viewModel
        presenter?.presentAudioBanner(viewController)

        (contentViewController, contentViewModel) = presentQuranContent(with: input)
        presenter?.startHiddenBarsTimer()
    }

    private func presentTranslationsSelection() {
        presenter?.dismissPresentedViewController {
            let controller = self.deps.translationsSelectionBuilder.build()
            self.presenter?.presentTranslationsSelection(controller)
        }
    }

    #if !QURAN_SYNC
    private func forceDeleteNotes(_ notes: [Note], verses: [AyahNumber]) async {
        contentViewModel?.removeAyahMenuHighlight()
        do {
            try await deps.noteService.removeNotes(with: verses)
        } catch {
            crasher.recordError(error, reason: "Failed to remove notes")
        }
    }
    #endif

    private func notesInteractingVerses(_ verses: [AyahNumber]) -> [Note] {
        deps.notesObserver.notes(interacting: verses)
    }

    #if QURAN_SYNC
    private func presentNoteEditor(mode: NoteEditorMode) {
        dismissAyahMenu()
        presenter?.rotateToPortraitIfPhone()
        let viewController = deps.noteEditorBuilder.build(withListener: self, mode: mode)
        presenter?.present(viewController, animated: true)
    }
    #else
    private func presentNoteEditor(note: Note) {
        dismissAyahMenu()
        presenter?.rotateToPortraitIfPhone()
        let viewController = deps.noteEditorBuilder.build(withListener: self, note: note)
        presenter?.present(viewController, animated: true)
    }
    #endif

    private func dismissWordPointer() {
        logger.info("Quran: dismiss word pointer")
        guard let viewController = wordPointer else {
            return
        }
        presenter?.dismissWordPointer(viewController)
        wordPointer = nil
    }

    private func showWordPointer(referenceView: UIView) {
        logger.info("Quran: show word pointer")
        presentWordPointerIfNeeded()
        wordPointer?.showWordPointer(referenceView: referenceView)
    }

    private func hideWordPointer() {
        logger.info("Quran: hide word pointer")
        wordPointer?.hideWordPointer { self.dismissWordPointer() }
    }

    private func presentWordPointerIfNeeded() {
        guard wordPointer == nil else {
            return
        }
        let viewController = deps.wordPointerBuilder.build(withListener: self)
        wordPointer = viewController
        presenter?.presentWordPointer(viewController)
    }

    // MARK: - Quran Content

    private func presentQuranContent(with input: QuranInput) -> (ContentViewController, ContentViewModel) {
        let (viewController, contentViewModel) = deps.contentBuilder.build(withListener: self, input: input)
        presenter?.presentQuranContent(viewController)
        return (viewController, contentViewModel)
    }

    // MARK: - Page Bookmark

    private func reloadPageBookmark() {
        logger.info("Quran: reloadPageBookmark")
        if !visiblePages.isEmpty {
            showPageBookmarkIfNeeded(for: visiblePages)
        }
    }

    private func bookmarked(_ pages: [Page]) -> Bool {
        #if QURAN_SYNC
        guard case .remove = ReadingBookmarkAction.page(
            visiblePages: pages,
            bookmark: deps.readingBookmarkObserver.bookmark
        ) else {
            return false
        }
        return true
        #else
        let visibleBookmarks = pageBookmarks.filter { pages.contains($0.page) }
        return !visibleBookmarks.isEmpty
        #endif
    }

    private func showPageBookmarkIfNeeded(for pages: [Page]) {
        presenter?.updateBookmark(bookmarked(pages))
    }
}

private extension Reading {
    var supportsWordPositions: Bool {
        switch self {
        case .hafs_1405:
            return true
        case .hafs_1421:
            return false
        case .hafs_1440:
            return false
        case .hafs_1439:
            return false
        case .hafs_1441:
            return false
        case .tajweed:
            // TODO: Enable word-by-word translation.
            // Tajweed ayah info contains words dimensions, but they don't match the word-by-word database.
            return false
        case .naskh:
            return false
        }
    }
}

private extension AnalyticsLibrary {
    func bookmarkPage(_ page: Page) {
        logEvent("BookmarkPage", value: page.pageNumber.description)
    }
}
