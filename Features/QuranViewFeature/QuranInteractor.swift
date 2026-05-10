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
#if QURAN_SYNC
    import BookmarksFeature
#endif
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
    func presentTranslatedVerse(_ viewController: UIViewController, didDismiss: @escaping () -> Void)
    func presentAudioBanner(_ audioBanner: UIViewController)
    func presentWordPointer(_ viewController: UIViewController)
    func presentQuranContent(_ viewController: UIViewController)
    func presentTranslationsSelection(_ viewController: UIViewController)

    func dismissWordPointer(_ viewController: UIViewController)
    func dismissPresentedViewController(completion: (() -> Void)?)

    #if QURAN_SYNC
        func showReadingBookmarkNudge(expanded: Bool, undo: @escaping () async -> Void)
        func hideReadingBookmarkNudge()
        func presentAyahBookmarkCollectionPicker(_ viewController: UIViewController)
    #endif
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
        let highlightsService: QuranHighlightsService
        let ayahMenuBuilder: AyahMenuBuilder
        let moreMenuBuilder: MoreMenuBuilder
        let audioBannerBuilder: AudioBannerBuilder
        let wordPointerBuilder: WordPointerBuilder
        let noteEditorBuilder: NoteEditorBuilder
        let contentBuilder: ContentBuilder
        let translationsSelectionBuilder: TranslationsListBuilder
        let translationVerseBuilder: TranslationVerseBuilder
        let resources: ReadingResourcesService
        #if QURAN_SYNC
            let syncedNoteService: MobileSyncNoteService?
            let syncedNoteEditorBuilder: SyncedNoteEditorBuilder?
            let syncedHighlightsObserver: QuranSyncedHighlightsObserver?
            let readingBookmarkService: ReadingBookmarkService?
            let ayahBookmarkCollectionService: AyahBookmarkCollectionService?
            let ayahBookmarkCollectionPickerBuilder: AyahBookmarkCollectionPickerBuilder?
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
            syncedNotesObservationTask?.cancel()
            readingBookmarkTask?.cancel()
            ayahBookmarkCollectionsTask?.cancel()
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
        #if QURAN_SYNC
            deps.syncedHighlightsObserver?.start()
            if let ayahBookmarkCollectionService = deps.ayahBookmarkCollectionService {
                startAyahBookmarkCollectionsObservation(ayahBookmarkCollectionService)
            }
            if let syncedNoteService = deps.syncedNoteService {
                startSyncedNotesObservation(syncedNoteService)
            } else {
                startLegacyNotesObservation()
            }
        #else
            startLegacyNotesObservation()
        #endif

        #if QURAN_SYNC
            if let readingBookmarkService = deps.readingBookmarkService {
                startReadingBookmarkObservation(readingBookmarkService)
            } else {
                startPageBookmarkObservation()
            }
        #else
            startPageBookmarkObservation()
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

    func deleteNotes(_ notes: [Note], verses: [AyahNumber]) async {
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

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {
        logger.info("Quran: share text")
        dismissAyahMenu()
        presenter?.shareText(lines, in: sourceView, at: point, completion: {})
    }

    func editNote(_ note: Note) {
        dismissAyahMenu()
        presenter?.rotateToPortraitIfPhone()
        let viewController = deps.noteEditorBuilder.build(withListener: self, note: note)
        presenter?.present(viewController, animated: true)
    }

    #if QURAN_SYNC
        func addSyncedNote(verses: [AyahNumber]) {
            guard let syncedNoteEditorBuilder = deps.syncedNoteEditorBuilder else {
                return
            }

            dismissAyahMenu()
            presenter?.rotateToPortraitIfPhone()
            let viewController = syncedNoteEditorBuilder.build(withListener: self, verses: verses)
            presenter?.present(viewController, animated: true)
        }
    #endif

    func dismissNoteEditor() {
        logger.info("Quran: dismiss note editor")
        presenter?.dismiss(animated: true)
    }

    #if QURAN_SYNC
        func saveVersesAsBookmark(_ verses: [AyahNumber]) {
            guard let ayahBookmarkCollectionPickerBuilder = deps.ayahBookmarkCollectionPickerBuilder else {
                return
            }

            contentViewModel?.removeAyahMenuHighlight()
            presenter?.dismissPresentedViewController { [weak self] in
                guard let self else { return }
                let viewController = ayahBookmarkCollectionPickerBuilder.build(
                    verses: verses,
                    didUpdateReadingBookmark: { [weak self] bookmark in
                        guard let self else {
                            return
                        }
                        readingBookmark = bookmark
                        if bookmark != nil, let readingBookmarkService = deps.readingBookmarkService {
                            showReadingBookmarkNudge(using: readingBookmarkService)
                        } else {
                            presenter?.hideReadingBookmarkNudge()
                        }
                    },
                    didFinish: { [weak self] in
                        self?.presenter?.dismissPresentedViewController(completion: nil)
                    }
                )
                presenter?.presentAyahBookmarkCollectionPicker(viewController)
            }
        }

        func removeVersesFromBookmarkCollections(_ verses: [AyahNumber]) async {
            guard let ayahBookmarkCollectionService = deps.ayahBookmarkCollectionService else {
                return
            }

            contentViewModel?.removeAyahMenuHighlight()
            dismissAyahMenu()

            let selectedVerses = Set(verses)
            do {
                for collection in ayahBookmarkCollections where HighlightColor(collectionName: collection.collection.name) == nil {
                    for bookmark in collection.bookmarks where selectedVerses.contains(bookmark.ayah) {
                        try await ayahBookmarkCollectionService.removeBookmarkFromCollection(bookmark)
                    }
                }
            } catch {
                crasher.recordError(error, reason: "Failed to remove ayah bookmark from collections")
            }
        }
    #endif

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
        let notes = notesInteractingVerses(verses)
        let input = AyahMenuInput(
            sourceView: sourceView,
            pointInView: point,
            verses: verses,
            notes: notes,
            noteCount: syncedNoteCount(interacting: verses),
            highlightColor: highlightColor(for: verses),
            isCollectionBookmarked: collectionBookmarked(verses)
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
        #if QURAN_SYNC
            if let readingBookmarkService = deps.readingBookmarkService {
                await toggleReadingBookmark(using: readingBookmarkService)
                return
            }
        #endif

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

    private var notes: [Note] = []
    #if QURAN_SYNC
        private var syncedNotes: [SyncedNote] = []
        private var syncedNotesObservationTask: Task<Void, Never>?
        private var readingBookmarkTask: Task<Void, Never>?
        private var ayahBookmarkCollectionsTask: Task<Void, Never>?
        private var ayahBookmarkCollections: [AyahBookmarkCollection] = []
        private var readingBookmark: QuranReadingBookmark? {
            didSet {
                reloadPageBookmark()
            }
        }
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

    private func startPageBookmarkObservation() {
        deps.pageBookmarkService.pageBookmarks(quran: deps.quran)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pageBookmarks = $0 }
            .store(in: &cancellables)
    }

    private func startLegacyNotesObservation() {
        deps.noteService.notes(quran: deps.quran)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.notes = $0 }
            .store(in: &cancellables)
    }

    #if QURAN_SYNC
        private func startSyncedNotesObservation(_ noteService: MobileSyncNoteService) {
            let quran = deps.quran
            syncedNotesObservationTask?.cancel()
            syncedNotesObservationTask = Task {
                do {
                    let sequence = noteService.notesSequence(quran: quran)
                    for try await notes in sequence {
                        await MainActor.run { [weak self] in
                            self?.syncedNotes = notes
                        }
                    }
                } catch is CancellationError {
                } catch {
                    crasher.recordError(error, reason: "Failed to observe synced notes")
                }
            }
        }

        private func startReadingBookmarkObservation(_ service: ReadingBookmarkService) {
            readingBookmarkTask?.cancel()
            readingBookmarkTask = Task { [weak self] in
                do {
                    let sequence = service.readingBookmarkSequence()
                    for try await bookmark in sequence {
                        await MainActor.run {
                            self?.readingBookmark = bookmark
                        }
                    }
                } catch {
                    crasher.recordError(error, reason: "Failed to observe reading bookmark")
                }
            }
        }

        private func startAyahBookmarkCollectionsObservation(_ service: AyahBookmarkCollectionService) {
            ayahBookmarkCollectionsTask?.cancel()
            ayahBookmarkCollectionsTask = Task { [weak self] in
                do {
                    let sequence = service.collectionsSequence()
                    for try await collections in sequence {
                        await MainActor.run {
                            self?.ayahBookmarkCollections = collections
                        }
                    }
                } catch {
                    crasher.recordError(error, reason: "Failed to observe ayah bookmark collections")
                }
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

    private func forceDeleteNotes(_ notes: [Note], verses: [AyahNumber]) async {
        contentViewModel?.removeAyahMenuHighlight()
        do {
            try await deps.noteService.removeNotes(with: verses)
        } catch {
            crasher.recordError(error, reason: "Failed to remove notes")
        }
    }

    private func notesInteractingVerses(_ verses: [AyahNumber]) -> [Note] {
        let selectedVerses = Set(verses)
        return notes.filter { !selectedVerses.isDisjoint(with: $0.verses) }
    }

    private func syncedNoteCount(interacting verses: [AyahNumber]) -> Int {
        #if QURAN_SYNC
            return SyncedNoteCounter.count(syncedNotes, interacting: verses)
        #else
            return 0
        #endif
    }

    private func collectionBookmarked(_ verses: [AyahNumber]) -> Bool {
        #if QURAN_SYNC
            let selectedVerses = Set(verses)
            return ayahBookmarkCollections.contains { collection in
                guard HighlightColor(collectionName: collection.collection.name) == nil else {
                    return false
                }
                return collection.bookmarks.contains { selectedVerses.contains($0.ayah) }
            }
        #else
            return false
        #endif
    }

    private func highlightColor(for verses: [AyahNumber]) -> HighlightColor? {
        let colors = verses.compactMap { deps.highlightsService.highlights.highlightVerses[$0] }
        guard colors.count == verses.count else {
            return nil
        }
        let uniqueColors = Set(colors)
        return uniqueColors.count == 1 ? uniqueColors.first : nil
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

    #if QURAN_SYNC
        private func toggleReadingBookmark(using service: ReadingBookmarkService) async {
            let pages = visiblePages
            guard let page = pages.first else {
                return
            }

            do {
                if readingBookmarked(pages) {
                    deps.analytics.removeBookmarkPage(page)
                    try await service.removeReadingBookmark()
                    readingBookmark = nil
                    presenter?.hideReadingBookmarkNudge()
                } else {
                    deps.analytics.bookmarkPage(page)
                    readingBookmark = try await service.addReadingBookmark(page: page)
                    showReadingBookmarkNudge(using: service)
                }
            } catch {
                crasher.recordError(error, reason: "Failed to toggle reading bookmark")
            }
        }

        private func showReadingBookmarkNudge(using service: ReadingBookmarkService) {
            let isExpanded = !ReadingBookmarkPreferences.shared.isEducationShown
            ReadingBookmarkPreferences.shared.isEducationShown = true
            presenter?.showReadingBookmarkNudge(expanded: isExpanded) { [weak self] in
                await self?.removeReadingBookmark(using: service)
            }
        }

        private func removeReadingBookmark(using service: ReadingBookmarkService) async {
            do {
                try await service.removeReadingBookmark()
                readingBookmark = nil
                presenter?.hideReadingBookmarkNudge()
            } catch {
                crasher.recordError(error, reason: "Failed to remove reading bookmark")
            }
        }
    #endif

    // MARK: - Page Bookmark

    private func reloadPageBookmark() {
        logger.info("Quran: reloadPageBookmark")
        if !visiblePages.isEmpty {
            showPageBookmarkIfNeeded(for: visiblePages)
        }
    }

    private func bookmarked(_ pages: [Page]) -> Bool {
        #if QURAN_SYNC
            if deps.readingBookmarkService != nil {
                return readingBookmarked(pages)
            }
        #endif

        let visibleBookmarks = pageBookmarks.filter { pages.contains($0.page) }
        return !visibleBookmarks.isEmpty
    }

    #if QURAN_SYNC
        private func readingBookmarked(_ pages: [Page]) -> Bool {
            readingBookmark?.isPageBookmark(for: pages) ?? false
        }
    #endif

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
