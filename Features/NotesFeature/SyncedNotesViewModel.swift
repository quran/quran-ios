#if QURAN_SYNC
    //
    //  SyncedNotesViewModel.swift
    //
    //  Created by Ahmed Nabil on 2026-05-16.
    //

    import AnnotationsService
    import Crashing
    import Foundation
    import Localization
    import QuranKit
    import QuranTextKit
    import ReadingService
    import SwiftUI
    import Utilities
    import VLogging

    @MainActor
    final class SyncedNotesViewModel: ObservableObject {
        // MARK: Lifecycle

        init(noteService: MobileSyncNoteService, textService: QuranTextDataService) {
            self.noteService = noteService
            self.textService = textService
        }

        // MARK: Internal

        @Published var editMode: EditMode = .inactive
        @Published var error: Error?
        @Published var notes: [SyncedNoteItem] = []
        @Published var searchTerm: String = ""

        var filteredNotes: [SyncedNoteItem] {
            let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else {
                return notes
            }
            return notes.filter { item in
                if item.note.body.range(of: term, options: .caseInsensitive) != nil {
                    return true
                }
                let suraName = item.note.firstVerse.sura.localizedName()
                return suraName.range(of: term, options: .caseInsensitive) != nil
            }
        }

        func start() async {
            do {
                let sequence = noteService.notesSequence(quran: readingPreferences.reading.quran)
                for try await notes in sequence {
                    self.notes = await noteItems(with: notes)
                }
            } catch {
                self.error = error
            }
        }

        func deleteItem(_ item: SyncedNoteItem) async {
            do {
                try await noteService.removeNote(item.note)
            } catch {
                self.error = error
            }
        }

        func prepareNotesForSharing() async throws -> String {
            try await crasher.recordError("Failed to share synced notes") {
                var notesText = [String]()
                let notes: [SyncedNoteItem] = await self.notes
                for (index, note) in notes.enumerated() {
                    notesText.append(contentsOf: [note.note.body.trimmingCharacters(in: .newlines), ""])
                    let verses = try await textForVerses(note.note.verses)
                    notesText.append(verses)
                    if index != notes.count - 1 {
                        notesText.append(contentsOf: ["", "", ""])
                    }
                }
                return notesText.joined(separator: "\n")
            }
        }

        // MARK: Private

        private let noteService: MobileSyncNoteService
        private let textService: QuranTextDataService
        private let readingPreferences = ReadingPreferences.shared

        private nonisolated func noteItems(with notes: [SyncedNote]) async -> [SyncedNoteItem] {
            await withTaskGroup(of: SyncedNoteItem.self) { group in
                for note in notes {
                    group.addTask {
                        do {
                            let verseText = try await self.textForVerses(note.verses)
                            return SyncedNoteItem(note: note, verseText: verseText)
                        } catch {
                            crasher.recordError(error, reason: "SyncedNotesViewModel.textForVerses")
                            return SyncedNoteItem(note: note, verseText: note.firstVerse.localizedName)
                        }
                    }
                }

                return await group.collect()
            }
        }

        private nonisolated func textForVerses(_ verses: [AyahNumber]) async throws -> String {
            let verseTexts = try await textService.textForVerses(verses, translations: [])
            return verses.sorted()
                .compactMap { verse in
                    verseTexts[verse].map { $0.arabicText + " \(NumberFormatter.arabicNumberFormatter.format(verse.ayah))" }
                }
                .joined(separator: " ")
        }
    }
#endif
