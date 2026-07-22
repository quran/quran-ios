//
//  NotesViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

#if !QURAN_SYNC
import Analytics
import Combine
#endif
import AnnotationsService
import Crashing
import Foundation
import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import QuranTextKit
import ReadingService
import SwiftUI
import Utilities
import VLogging

@MainActor
final class NotesViewModel: ObservableObject {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        noteService: MobileSyncNoteService,
        textService: QuranTextDataService,
        textRetriever: ShareableVerseTextRetriever,
        navigateTo: @escaping (AyahNumber) -> Void,
        editNote: @escaping (Note) -> Void
    ) {
        self.noteService = noteService
        self.textService = textService
        self.textRetriever = textRetriever
        self.navigateTo = navigateTo
        editNoteAction = editNote
    }
    #else
    init(
        analytics: AnalyticsLibrary,
        noteService: NoteService,
        textRetriever: ShareableVerseTextRetriever,
        textService: QuranTextDataService,
        navigateTo: @escaping (AyahNumber) -> Void,
        editNote: @escaping (Note) -> Void
    ) {
        self.analytics = analytics
        self.noteService = noteService
        self.textRetriever = textRetriever
        self.textService = textService
        self.navigateTo = navigateTo
        editNoteAction = editNote
    }
    #endif

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    @Published var notes: [NoteItem] = []
    @Published var searchTerm: String = ""

    var filteredNotes: [NoteItem] {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return notes
        }
        return notes.filter { item in
            if item.noteText.range(of: term, options: .caseInsensitive) != nil {
                return true
            }
            let suraName = item.note.startAyah.sura.localizedName()
            return suraName.range(of: term, options: .caseInsensitive) != nil
        }
    }

    func start() async {
        #if QURAN_SYNC
        do {
            let sequence = noteService.notesSequence(quran: readingPreferences.reading.quran)
            for try await notes in sequence {
                self.notes = await noteItems(with: notes)
            }
        } catch {
            self.error = error
        }
        #else
        let notesSequence = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [noteService] reading in
                noteService.notes(quran: reading.quran)
            }
            .switchToLatest()
            .values()

        for await notes in notesSequence {
            self.notes = await noteItems(with: notes)
                .sorted { $0.note.modifiedDate > $1.note.modifiedDate }
        }
        #endif
    }

    func navigateTo(_ item: NoteItem) {
        logger.info("Notes: select note at \(item.note.startAyah)")
        navigateTo(item.note.startAyah)
    }

    func editNote(_ item: NoteItem) {
        logger.info("Notes: edit note at \(item.note.startAyah)")
        editNoteAction(item.note)
    }

    func deleteItem(_ item: NoteItem) async {
        #if QURAN_SYNC
        do {
            try await noteService.removeNote(item.note)
        } catch {
            self.error = error
        }
        #else
        logger.info("Notes: delete note at \(item.note.startAyah)")
        do {
            try await noteService.removeNotes(with: Array(item.note.verses))
        } catch {
            self.error = error
        }
        #endif
    }

    func prepareNotesForSharing() async throws -> String {
        #if QURAN_SYNC
        let errorReason = "Failed to share synced notes"
        #else
        let errorReason = "Failed to share notes"
        #endif
        return try await crasher.recordError(errorReason) {
            var notesText = [String]()
            let notes: [NoteItem] = await self.notes
            for (index, note) in notes.enumerated() {
                #if QURAN_SYNC
                let title = [note.noteText.trimmingCharacters(in: .newlines), ""]
                #else
                let title: [String] = if !note.noteText.isEmpty {
                    [
                        "\(note.noteText.trimmingCharacters(in: .newlines))", "",
                    ]
                } else {
                    []
                }
                #endif
                let verses = try await textRetriever.textForVerses(note.note.verses)

                notesText.append(contentsOf: title + verses)
                if index != notes.count - 1 {
                    notesText.append(contentsOf: ["", "", ""])
                }
            }
            return notesText.joined(separator: "\n")
        }
    }

    // MARK: Private

    #if QURAN_SYNC
    private let noteService: MobileSyncNoteService
    #else
    private let analytics: AnalyticsLibrary
    private let noteService: NoteService
    #endif
    private let textService: QuranTextDataService
    private let textRetriever: ShareableVerseTextRetriever
    private let navigateTo: (AyahNumber) -> Void
    private let editNoteAction: (Note) -> Void
    private let readingPreferences = ReadingPreferences.shared

    private nonisolated func noteItems(with notes: [Note]) async -> [NoteItem] {
        #if QURAN_SYNC
        await withTaskGroup(of: (Int, NoteItem).self) { group in
            for (index, note) in notes.enumerated() {
                group.addTask {
                    (index, await self.noteItem(with: note))
                }
            }

            return await group.collect()
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
        #else
        await withTaskGroup(of: NoteItem.self) { group in
            for note in notes {
                group.addTask {
                    await self.noteItem(with: note)
                }
            }

            return await group.collect()
        }
        #endif
    }

    private nonisolated func noteItem(with note: Note) async -> NoteItem {
        do {
            let verseText = try await textService.numberedArabicText(for: note.verses)
            return NoteItem(note: note, quranText: verseText)
        } catch {
            crasher.recordError(error, reason: "NotesViewModel.textForVerses")
            return NoteItem(note: note, quranText: nil)
        }
    }
}
