#if QURAN_SYNC
//
//  AyahNotesViewModel.swift
//

import AnnotationsService
import Foundation
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx
import VLogging

@MainActor
final class AyahNotesViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        verses: [AyahNumber],
        noteService: MobileSyncNoteService
    ) {
        self.verses = Array(Set(verses)).sorted()
        self.noteService = noteService
    }

    // MARK: Internal

    @Published private(set) var notes: [Note] = []
    @Published var editMode: EditMode = .inactive
    @Published var error: Error?

    let verses: [AyahNumber]

    func start() async {
        await observeNotes()
    }

    func deleteNote(_ note: Note) -> AsyncAction? {
        guard pendingDeletionIDs.insert(note.id).inserted else {
            return nil
        }
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            pendingDeletionIDs.remove(note.id)
            return nil
        }

        notes.remove(at: index)

        return { [weak self] in
            guard let self else { return }
            do {
                try await noteService.removeNote(note)
            } catch is CancellationError {
                restore(note, at: index)
            } catch {
                logger.error("Ayah notes: failed to delete note: \(error)")
                restore(note, at: index)
                self.error = error
            }
            pendingDeletionIDs.remove(note.id)
        }
    }

    // MARK: Private

    private let noteService: MobileSyncNoteService
    private var pendingDeletionIDs: Set<Note.ID> = []

    private func observeNotes() async {
        guard let quran = verses.first?.quran else {
            notes = []
            return
        }

        do {
            for try await notes in noteService.notesSequence(quran: quran) {
                let matchingNotes = notes.filter {
                    $0.intersects(verses: verses) && !pendingDeletionIDs.contains($0.id)
                }
                self.notes = matchingNotes
                if matchingNotes.isEmpty {
                    editMode = .inactive
                }
            }
        } catch is CancellationError {
        } catch {
            logger.error("Ayah notes: failed to observe notes: \(error)")
            self.error = error
        }
    }

    private func restore(_ note: Note, at index: Int) {
        notes.removeAll { $0.id == note.id }
        notes.insert(note, at: min(index, notes.endIndex))
    }
}
#endif
