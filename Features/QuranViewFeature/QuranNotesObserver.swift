import AnnotationsService
import Combine
#if QURAN_SYNC
import Crashing
#endif
import Foundation
import QuranAnnotations
import QuranKit

@MainActor
final class QuranNotesObserver {
    #if QURAN_SYNC
    init(noteService: MobileSyncNoteService, quran: Quran) {
        self.noteService = noteService
        self.quran = quran
    }
    #else
    init(noteService: NoteService, quran: Quran) {
        self.noteService = noteService
        self.quran = quran
    }
    #endif

    deinit {
        #if QURAN_SYNC
        task?.cancel()
        #endif
    }

    @Published private(set) var notes: [Note] = []

    func start() {
        #if QURAN_SYNC
        guard task == nil else {
            return
        }
        let noteService = noteService
        let quran = quran
        task = Task { [weak self] in
            do {
                for try await notes in noteService.notesSequence(quran: quran) {
                    self?.notes = notes
                }
            } catch is CancellationError {
            } catch {
                crasher.recordError(error, reason: "Failed to observe notes")
            }
        }
        #else
        guard observation == nil else {
            return
        }
        observation = noteService.notes(quran: quran)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.notes = $0 }
        #endif
    }

    func notes(interacting verses: [AyahNumber]) -> [Note] {
        notes.filter { $0.intersects(verses: verses) }
    }

    #if !QURAN_SYNC
    func prepareNote(for verses: [AyahNumber]) async throws -> Note {
        let color = noteService.color(from: notes(interacting: verses))
        return try await noteService.updateHighlight(verses: verses, color: color, quran: quran)
    }
    #endif

    #if QURAN_SYNC
    func remove(_ note: Note) async throws {
        try await noteService.removeNote(note)
    }
    #endif

    #if QURAN_SYNC
    private let noteService: MobileSyncNoteService
    private var task: Task<Void, Never>?
    #else
    private let noteService: NoteService
    private var observation: AnyCancellable?
    #endif
    private let quran: Quran
}
