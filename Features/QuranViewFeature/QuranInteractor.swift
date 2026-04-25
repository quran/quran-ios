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
import Combine
import Crashing
import FeaturesSupport
import MoreMenuFeature
#if QURAN_SYNC
    import MobileSync
    import MobileSyncSupport
#endif
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
    func presentTranslatedVerse(_ viewController: UIViewController, didDismiss: @escaping () -> Void)
    func presentAudioBanner(_ audioBanner: UIViewController)
    func presentWordPointer(_ viewController: UIViewController)
    func presentQuranContent(_ viewController: UIViewController)
    func presentTranslationsSelection(_ viewController: UIViewController)

    func dismissWordPointer(_ viewController: UIViewController)
    func dismissPresentedViewController(completion: (() -> Void)?)
}

@MainActor
final class QuranInteractor: WordPointerListener, ContentListener, NoteEditorListener,
    MoreMenuListener, AudioBannerListener, AyahMenuListener
{
    struct Deps {
        let quran: Quran
        let analytics: AnalyticsLibrary
        let pageBookmarkService: PageBookmarkService
        let noteService: NoteService
        let ayahMenuBuilder: AyahMenuBuilder
        #if QURAN_SYNC
            let syncedAyahMenuBuilder: SyncedAyahMenuBuilder?
        #endif
        let moreMenuBuilder: MoreMenuBuilder
        let audioBannerBuilder: AudioBannerBuilder
        let wordPointerBuilder: WordPointerBuilder
        let noteEditorBuilder: NoteEditorBuilder
        #if QURAN_SYNC
            let syncedNoteEditorBuilder: SyncedNoteEditorBuilder?
        #endif
        let contentBuilder: ContentBuilder
        let translationsSelectionBuilder: TranslationsListBuilder
        let translationVerseBuilder: TranslationVerseBuilder
        let resources: ReadingResourcesService
        #if QURAN_SYNC
            let syncService: SyncService?
            let bookmarkCollectionService: BookmarkCollectionService?
        #endif
    }

    // MARK: Lifecycle

    init(deps: Deps, input: QuranInput) {
        self.deps = deps
        self.input = input
        logger.info("Quran: opening quran \(input)")
    }

    deinit {
        #if QURAN_SYNC
            syncNotesTask?.cancel()
        #endif
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
        deps.noteService.notes(quran: deps.quran)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                guard let self else { return }
                #if QURAN_SYNC
                    if deps.syncService != nil {
                        self.notes = notes.filter { !(($0.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                    } else {
                        self.notes = notes
                    }
                #else
                    self.notes = notes
                #endif
            }
            .store(in: &cancellables)

        deps.pageBookmarkService.pageBookmarks(quran: deps.quran)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pageBookmarks = $0 }
            .store(in: &cancellables)

        contentStatePreferences.$quranMode
            .sink { [weak self] _ in self?.onQuranModeUpdated() }
            .store(in: &cancellables)

        #if QURAN_SYNC
            if let syncService = deps.syncService {
                syncNotesTask = Task { [weak self] in
                    do {
                        for try await notes in syncService.notesSequence() {
                            guard let self else { return }
                            syncNotes = SyncedNoteReference.makeAll(from: notes, quran: deps.quran)
                        }
                    } catch is CancellationError {
                    } catch {
                        crasher.recordError(error, reason: "Failed to observe synced notes")
                    }
                }
            }
        #endif

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

    func deleteNotes(_ notes: [QuranAnnotations.Note], verses: [AyahNumber]) async {
        let containsText = notes.contains { note in
            !(note.note ?? "").isEmpty
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
    }

    #if QURAN_SYNC
        func deleteSyncHighlights(_ verses: [AyahNumber]) async {
            contentViewModel?.removeAyahMenuHighlight()
            do {
                guard let syncService = deps.syncService,
                      let bookmarkCollectionService = deps.bookmarkCollectionService
                else {
                    return
                }

                try await HighlightCollection.removeHighlights(
                    verses: verses,
                    syncService: syncService,
                    bookmarkCollectionService: bookmarkCollectionService
                )
            } catch {
                crasher.recordError(error, reason: "Failed to remove synced highlights")
            }
        }

        func deleteSyncedNotes(_ notes: [SyncedNoteReference], verses _: [AyahNumber]) async {
            contentViewModel?.removeAyahMenuHighlight()

            func performDelete() async {
                for note in notes {
                    guard let localId = note.localId else {
                        continue
                    }
                    do {
                        try await deps.syncService?.removeNote(localId: localId)
                    } catch {
                        crasher.recordError(error, reason: "Failed to remove synced note")
                    }
                }
            }

            if notes.contains(where: { !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                presenter?.confirmNoteDelete(
                    delete: { await performDelete() },
                    cancel: { self.contentViewModel?.removeAyahMenuHighlight() }
                )
            } else {
                await performDelete()
            }
        }

        func editSyncedNote(_ note: SyncedNoteReference) {
            dismissAyahMenu()
            presenter?.rotateToPortraitIfPhone()
            guard let syncedNoteEditorBuilder = deps.syncedNoteEditorBuilder else {
                return
            }
            let viewController = syncedNoteEditorBuilder.build(withListener: self, note: note)
            presenter?.present(viewController, animated: true)
        }
    #endif

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {
        logger.info("Quran: share text")
        dismissAyahMenu()
        presenter?.shareText(lines, in: sourceView, at: point, completion: {})
    }

    func editNote(_ note: QuranAnnotations.Note) {
        dismissAyahMenu()
        presenter?.rotateToPortraitIfPhone()
        let viewController = deps.noteEditorBuilder.build(withListener: self, note: note)
        presenter?.present(viewController, animated: true)
    }

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

    func presentAyahMenu(
        in sourceView: UIView,
        at point: CGPoint,
        verses: [AyahNumber],
        notes: [QuranAnnotations.Note],
        syncHighlightColor: HighlightColor?,
        hasSyncHighlight: Bool
    ) {
        logger.info("Quran: present ayah menu, verses: \(verses)")
        let notes = notes.isEmpty ? notesInteractingVerses(verses) : notes
        #if QURAN_SYNC
            if let syncedAyahMenuBuilder = deps.syncedAyahMenuBuilder, deps.syncService != nil {
                let syncNotes = syncedNotesInteractingVerses(verses)
                let input = SyncedAyahMenuInput(
                    sourceView: sourceView,
                    pointInView: point,
                    verses: verses,
                    notes: syncNotes,
                    syncHighlightColor: syncHighlightColor,
                    hasSyncHighlight: hasSyncHighlight
                )
                let ayahMenuViewController = syncedAyahMenuBuilder.build(withListener: self, input: input)
                presenter?.presentAyahMenu(ayahMenuViewController, in: sourceView, at: point)
                return
            }
        #endif

        let input = AyahMenuInput(
            sourceView: sourceView,
            pointInView: point,
            verses: verses,
            notes: notes
        )
        let ayahMenuViewController = deps.ayahMenuBuilder.build(withListener: self, input: input)
        presenter?.presentAyahMenu(ayahMenuViewController, in: sourceView, at: point)
    }

    func dismissAyahMenu() {
        logger.info("Quran: dismiss ayah menu")
        presenter?.dismissPresentedViewController(completion: nil)
        contentViewModel?.removeAyahMenuHighlight()
    }

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
    }

    // MARK: Private

    private let readingPreferences = ReadingPreferences.shared
    private let contentStatePreferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    private var notes: [QuranAnnotations.Note] = []

    #if QURAN_SYNC
        private var syncNotes: [SyncedNoteReference] = []
        private var syncNotesTask: Task<Void, Never>?
    #endif

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

    private var pageBookmarks: [PageBookmark] = [] {
        didSet {
            reloadPageBookmark()
        }
    }

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

    private func forceDeleteNotes(_ notes: [QuranAnnotations.Note], verses: [AyahNumber]) async {
        contentViewModel?.removeAyahMenuHighlight()
        do {
            try await deps.noteService.removeNotes(with: verses)
        } catch {
            crasher.recordError(error, reason: "Failed to remove notes")
        }
    }

    private func notesInteractingVerses(_ verses: [AyahNumber]) -> [QuranAnnotations.Note] {
        let selectedVerses = Set(verses)
        return notes.filter { !selectedVerses.isDisjoint(with: $0.verses) }
    }

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

    #if QURAN_SYNC
        private func syncedNotesInteractingVerses(_ verses: [AyahNumber]) -> [SyncedNoteReference] {
            syncNotes.filter { note in
                !Set(note.verses).isDisjoint(with: verses)
            }
        }
    #endif

    private func bookmarked(_ pages: [Page]) -> Bool {
        let visibleBookmarks = pageBookmarks.filter { pages.contains($0.page) }
        return !visibleBookmarks.isEmpty
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
        }
    }
}

private extension AnalyticsLibrary {
    func bookmarkPage(_ page: Page) {
        logEvent("BookmarkPage", value: page.pageNumber.description)
    }
}

#if QURAN_SYNC
    extension QuranInteractor: SyncedAyahMenuListener { }
#endif
