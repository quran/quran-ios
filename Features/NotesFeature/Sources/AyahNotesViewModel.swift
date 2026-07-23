#if QURAN_SYNC
//
//  AyahNotesViewModel.swift
//

import AnnotationsService
import Foundation
import QuranAnnotations
import QuranKit
import SwiftUI
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

    func deleteNote(_ note: Note) async {
        do {
            try await noteService.removeNote(note)
        } catch is CancellationError {
        } catch {
            logger.error("Ayah notes: failed to delete note: \(error)")
            self.error = error
        }
    }

    // MARK: Private

    private let noteService: MobileSyncNoteService

    private func observeNotes() async {
        guard let quran = verses.first?.quran else {
            notes = []
            return
        }

        do {
            for try await notes in noteService.notesSequence(quran: quran) {
                let matchingNotes = notes.filter { $0.intersects(verses: verses) }
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
}
#endif
