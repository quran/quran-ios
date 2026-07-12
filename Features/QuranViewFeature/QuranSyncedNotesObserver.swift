#if QURAN_SYNC
import AnnotationsService
import Combine
import Crashing
import QuranAnnotations
import QuranKit
import VLogging

@MainActor
final class QuranSyncedNotesObserver {
    init(noteService: MobileSyncNoteService, quran: Quran) {
        self.noteService = noteService
        self.quran = quran
    }

    deinit {
        task?.cancel()
    }

    @Published private(set) var notes: [Note] = []

    func start() {
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
                crasher.recordError(error, reason: "Failed to observe synced notes")
            }
        }
    }

    func notes(interacting verses: [AyahNumber]) -> [Note] {
        notes.filter { $0.intersects(verses: verses) }
    }

    func remove(_ note: Note) async throws {
        try await noteService.removeNote(note)
    }

    private let noteService: MobileSyncNoteService
    private let quran: Quran
    private var task: Task<Void, Never>?
}
#endif
