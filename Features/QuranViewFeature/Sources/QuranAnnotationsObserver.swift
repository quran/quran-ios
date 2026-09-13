import AnnotationsService
import Combine
#if QURAN_SYNC
import Crashing
#endif
import Foundation
import QuranAnnotations
import QuranKit

@MainActor
final class QuranAnnotationsObserver {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        noteService: MobileSyncNoteService,
        highlightService: MobileSyncAyahHighlightService,
        collectionService: AyahBookmarkCollectionService,
        readingBookmarkService: MobileSyncReadingBookmarkService,
        quran: Quran,
        highlightsService: QuranHighlightsService
    ) {
        self.noteService = noteService
        self.highlightService = highlightService
        self.collectionService = collectionService
        self.readingBookmarkService = readingBookmarkService
        self.quran = quran
        self.highlightsService = highlightsService
    }
    #else
    init(noteService: NoteService, quran: Quran, highlightsService: QuranHighlightsService) {
        self.noteService = noteService
        self.quran = quran
        self.highlightsService = highlightsService
    }
    #endif

    deinit {
        #if QURAN_SYNC
        notesTask?.cancel()
        highlightsTask?.cancel()
        collectionsTask?.cancel()
        readingBookmarksTask?.cancel()
        #endif
    }

    // MARK: Internal

    @Published private(set) var notes: [Note] = []
    #if QURAN_SYNC
    private(set) var collections: [AyahBookmarkCollection] = []
    @Published private(set) var readingBookmarks: [PlacedReadingBookmark] = []
    #endif

    func start() {
        #if QURAN_SYNC
        observe(
            noteService.notesSequence(quran: quran),
            task: \.notesTask,
            failureReason: "Failed to observe notes in Quran"
        ) { observer, notes in
            observer.updateNotes(notes)
        }
        observe(
            highlightService.highlightsSequence(),
            task: \.highlightsTask,
            failureReason: "Failed to observe saved highlights in Quran"
        ) { observer, highlights in
            observer.updateHighlights(highlights)
        }
        observe(
            collectionService.collectionsSequence(),
            task: \.collectionsTask,
            failureReason: "Failed to observe bookmark collections in Quran"
        ) { observer, collections in
            observer.updateCollections(collections)
        }
        observe(
            readingBookmarkService.placedReadingBookmarksSequence(quran: quran),
            task: \.readingBookmarksTask,
            failureReason: "Failed to observe reading bookmarks in Quran"
        ) { observer, bookmarks in
            observer.updateReadingBookmarks(bookmarks)
        }
        #else
        guard notesObservation == nil else { return }
        notesObservation = noteService.notes(quran: quran)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateNotes($0) }
        #endif
    }

    func stop() {
        #if QURAN_SYNC
        notesTask?.cancel()
        notesTask = nil
        highlightsTask?.cancel()
        highlightsTask = nil
        collectionsTask?.cancel()
        collectionsTask = nil
        readingBookmarksTask?.cancel()
        readingBookmarksTask = nil
        #else
        notesObservation?.cancel()
        notesObservation = nil
        #endif
    }

    func notes(interacting verses: [AyahNumber]) -> [Note] {
        notes.filter { $0.intersects(verses: verses) }
    }

    #if QURAN_SYNC
    func latestReadingBookmark(at placements: [PlacedReadingBookmark.Placement]) -> PlacedReadingBookmark? {
        readingBookmarks
            .filter { placements.contains($0.placement) }
            .max { $0.modifiedOn < $1.modifiedOn }
    }
    #endif

    // MARK: Private

    private let quran: Quran
    private let highlightsService: QuranHighlightsService
    #if QURAN_SYNC
    private let noteService: MobileSyncNoteService
    private let highlightService: MobileSyncAyahHighlightService
    private let collectionService: AyahBookmarkCollectionService
    private let readingBookmarkService: MobileSyncReadingBookmarkService
    private var notesTask: Task<Void, Never>?
    private var highlightsTask: Task<Void, Never>?
    private var collectionsTask: Task<Void, Never>?
    private var readingBookmarksTask: Task<Void, Never>?
    #else
    private let noteService: NoteService
    private var notesObservation: AnyCancellable?
    #endif

    private func updateNotes(_ notes: [Note]) {
        self.notes = notes
        highlightsService.highlights.noteVerses = Set(notes.flatMap(\.verses))
        #if !QURAN_SYNC
        highlightsService.highlights.highlightVerses = notes.reduce(into: [:]) { colors, note in
            for verse in note.verses {
                colors[verse] = note.color
            }
        }
        #endif
    }

    #if QURAN_SYNC
    private func observe<Sequence: AsyncSequence>(
        _ sequence: Sequence,
        task: ReferenceWritableKeyPath<QuranAnnotationsObserver, Task<Void, Never>?>,
        failureReason: String,
        receive: @escaping @MainActor (QuranAnnotationsObserver, Sequence.Element) -> Void
    ) {
        guard self[keyPath: task] == nil else { return }

        self[keyPath: task] = Task { [weak self] in
            defer {
                // A cancelled task must not clear a replacement started after stop().
                if !Task.isCancelled {
                    self?[keyPath: task] = nil
                }
            }

            do {
                for try await value in sequence {
                    guard !Task.isCancelled, let self else { return }
                    receive(self, value)
                }
            } catch is CancellationError {
            } catch {
                if !Task.isCancelled {
                    crasher.recordError(error, reason: failureReason)
                }
            }
        }
    }

    private func updateHighlights(_ verses: [AyahNumber: HighlightColor]) {
        highlightsService.highlights.highlightVerses = verses
    }

    private func updateCollections(_ collections: [AyahBookmarkCollection]) {
        self.collections = collections
        highlightsService.highlights.collectionVerses = Set(collections.flatMap { $0.bookmarks.map(\.ayah) })
    }

    private func updateReadingBookmarks(_ bookmarks: [PlacedReadingBookmark]) {
        readingBookmarks = bookmarks
        highlightsService.highlights.readingBookmarks = bookmarks
    }
    #endif
}
