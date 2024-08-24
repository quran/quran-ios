//
//  NotesViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import Analytics
import AnnotationsService
import Combine
import Crashing
import Foundation
import Localization
import QuranAnnotations
import QuranKit
import QuranTextKit
import ReadingService
import SwiftUI
import Utilities
import VLogging

@MainActor
final class NotesViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        noteService: NoteService,
        textRetriever: ShareableVerseTextRetriever,
        navigateTo: @escaping (AyahNumber) -> Void
    ) {
        self.analytics = analytics
        self.noteService = noteService
        self.textRetriever = textRetriever
        self.navigateTo = navigateTo
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    @Published var notes: [NoteItem] = []

    func start() async {
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
    }

    func navigateTo(_ item: NoteItem) {
        logger.info("Notes: select note at \(item.note.firstVerse)")
        navigateTo(item.note.firstVerse)
    }

    func deleteItem(_ item: NoteItem) async {
        logger.info("Notes: delete note at \(item.note.firstVerse)")
        do {
            try await noteService.removeNotes(with: Array(item.note.verses))
        } catch {
            self.error = error
        }
    }

    func prepareNotesForSharing() async throws -> String {
        try await crasher.recordError("Failed to share notes") {
            var notesText = [String]()
            for note in await notes {
                let title = if let noteContent = note.note.note, noteContent != "" {
                    "\(noteContent.trimmingCharacters(in: .newlines))\n\n"
                } else {
                    ""
                }
                let verses = try await textRetriever.textForVerses(Array(note.note.verses)).joined(separator: "\n")

                notesText.append("\(title)\(verses)")
            }
            return notesText.joined(separator: "\n\n\n\n")
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let noteService: NoteService
    private let textRetriever: ShareableVerseTextRetriever
    private let navigateTo: (AyahNumber) -> Void
    private let readingPreferences = ReadingPreferences.shared

    private func noteItems(with notes: [Note]) async -> [NoteItem] {
        await withTaskGroup(of: NoteItem.self) { group in
            for note in notes {
                group.addTask {
                    do {
                        let verseText = try await self.noteService.textForVerses(Array(note.verses))
                        return NoteItem(note: note, verseText: verseText)
                    } catch {
                        crasher.recordError(error, reason: "NoteService.textForVerses")
                        return NoteItem(note: note, verseText: note.firstVerse.localizedName)
                    }
                }
            }

            let result = await group.collect()
            return result
        }
    }
}
