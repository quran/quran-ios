//
//  NotesViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

#if !QURAN_SYNC
import Combine
#else
import AuthenticationClient
import Combine
import LegacyDataMigration
import MobileSync
#endif
import AnnotationsService
import Crashing
import Foundation
import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import QuranLocalization
import QuranTextKit
import ReadingService
import SwiftUI
import UIx
import Utilities
import VLogging

@MainActor
final class NotesViewModel: ObservableObject {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        authenticationClient: any AuthenticationClient,
        quranDataService: MobileSyncDataService,
        noteService: MobileSyncNoteService,
        ayahHighlightService: MobileSyncAyahHighlightService,
        textService: QuranTextDataService,
        textRetriever: ShareableVerseTextRetriever,
        navigateTo: @escaping (AyahNumber) -> Void,
        editNote: @escaping (Note) -> Void,
        showHighlights: @escaping () -> Void
    ) {
        self.authenticationClient = authenticationClient
        self.quranDataService = quranDataService
        self.noteService = noteService
        self.ayahHighlightService = ayahHighlightService
        showHighlightsAction = showHighlights
        hadLegacyHighlights = legacyImportPreferences.hadHighlights
        isHighlightsTipDismissed = notesPreferences.isHighlightsTipDismissed
        self.textService = textService
        self.textRetriever = textRetriever
        reading = ReadingPreferences.shared.reading
        self.navigateTo = navigateTo
        editNoteAction = editNote
        readingPreferences.$reading
            .assign(to: &$reading)
        // Follow sign-in and sign-out elsewhere, such as in Settings.
        authenticationClient.authenticationStateChanges
            .map { $0 == .authenticated }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
        // A late CloudKit arrival can bring 3.0 highlights after Notes appears.
        legacyImportPreferences.$hadHighlights
            .receive(on: DispatchQueue.main)
            .assign(to: &$hadLegacyHighlights)
    }
    #else
    init(
        noteService: NoteService,
        textRetriever: ShareableVerseTextRetriever,
        textService: QuranTextDataService,
        navigateTo: @escaping (AyahNumber) -> Void,
        editNote: @escaping (Note) -> Void
    ) {
        self.noteService = noteService
        self.textRetriever = textRetriever
        self.textService = textService
        reading = ReadingPreferences.shared.reading
        self.navigateTo = navigateTo
        editNoteAction = editNote
        readingPreferences.$reading
            .assign(to: &$reading)
    }
    #endif

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    #if QURAN_SYNC
    @Published var isAuthenticated = false
    @Published var highlights: [AyahNumber: HighlightColor] = [:]
    @Published private(set) var hadLegacyHighlights: Bool
    @Published private(set) var isHighlightsTipDismissed: Bool
    #endif
    @Published var notes: [NoteItem] = []
    @Published var searchTerm: String = ""
    @Published var reading: Reading

    #if QURAN_SYNC
    /// Pull-to-refresh, when signed in. Not tied to edit mode: toggling it rebuilds the list.
    var canRefresh: Bool {
        isAuthenticated
    }

    /// The "Highlights now live in Bookmarks" card, for upgraders whose 3.0 notes held highlights
    /// that they still have.
    var showsHighlightsTip: Bool {
        hadLegacyHighlights && !highlights.isEmpty && !isHighlightsTipDismissed
    }

    /// Where the user's highlights went, for the empty state.
    var highlightsSummary: NotesHighlightsSummary? {
        guard !highlights.isEmpty else {
            return nil
        }
        let colors = Set(highlights.values)
        return NotesHighlightsSummary(
            colors: Array(HighlightColor.sortedColors.filter(colors.contains).prefix(4)),
            upgraderCount: hadLegacyHighlights ? highlights.count : nil
        )
    }
    #endif

    var filteredNotes: [NoteItem] {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return notes
        }
        return notes.filter { item in
            if item.noteText.range(of: term, options: .caseInsensitive) != nil {
                return true
            }
            let suras = Set(item.note.verses.map(\.sura))
            return suras.contains { $0.localizedName().range(of: term, options: .caseInsensitive) != nil }
        }
    }

    func start() async {
        #if QURAN_SYNC
        isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated
        logger.info("Quran Sync: restored authentication from Notes. Authenticated: \(isAuthenticated)")
        async let observingNotes: Void = observeNotes()
        async let observingHighlights: Void = observeHighlights()
        _ = await (observingNotes, observingHighlights)
        #else
        let notesSequence = $reading
            .map { [noteService] reading in
                noteService.notes(quran: reading.quran)
            }
            .switchToLatest()
            .values()

        for await notes in notesSequence {
            self.notes = await noteItems(with: notes)
                .filter { !pendingDeletionIDs.contains($0.id) }
                .sorted { $0.note.modifiedDate > $1.note.modifiedDate }
        }
        #endif
    }

    #if QURAN_SYNC
    /// Waits for a sync; failures are only logged, as Settings › Sync shows them.
    /// - Returns: `nil` when signed out or it stopped waiting.
    @discardableResult
    func refresh() async -> MobileSyncNowResult? {
        guard isAuthenticated else {
            return nil
        }
        logger.info("Quran Sync: userRequestedRefresh from Notes")
        do {
            let result = try await quranDataService.syncNow()
            logger.info("Quran Sync: refresh from Notes finished. \(result)")
            return result
        } catch is CancellationError {
            logger.info("Quran Sync: stopped waiting for the refresh from Notes; the sync goes on")
        } catch {
            logger.error("Quran Sync: refresh from Notes failed: \(error)")
        }
        return nil
    }

    /// Opens the Bookmarks tab, which lists highlights by color, and retires the card.
    func showHighlights() {
        logger.info("Notes: show highlights in Bookmarks")
        dismissHighlightsTip()
        showHighlightsAction()
    }

    func dismissHighlightsTip() {
        notesPreferences.isHighlightsTipDismissed = true
        isHighlightsTipDismissed = true
    }
    #endif

    func navigateTo(_ item: NoteItem) {
        logger.info("Notes: select note at \(item.note.startAyah.nonLocalizedDescription)")
        navigateTo(item.note.startAyah)
    }

    func editNote(_ item: NoteItem) {
        logger.info("Notes: edit note at \(item.note.startAyah.nonLocalizedDescription)")
        editNoteAction(item.note)
    }

    func deleteItem(_ item: NoteItem) -> AsyncAction? {
        guard pendingDeletionIDs.insert(item.id).inserted else {
            return nil
        }
        guard let index = notes.firstIndex(where: { $0.id == item.id }) else {
            pendingDeletionIDs.remove(item.id)
            return nil
        }

        notes.remove(at: index)

        return { [weak self] in
            guard let self else { return }
            #if QURAN_SYNC
            logger.info("Quran Sync: deleting note spanning \(item.note.verses.count) ayah(s)")
            do {
                try await noteService.removeNote(item.note)
            } catch {
                logger.error("Quran Sync: failed to delete note: \(error)")
                restore(item, at: index)
                self.error = error
            }
            #else
            logger.info("Notes: delete note at \(item.note.startAyah.nonLocalizedDescription)")
            do {
                try await noteService.removeNotes(with: Array(item.note.verses))
            } catch {
                restore(item, at: index)
                self.error = error
            }
            #endif
            pendingDeletionIDs.remove(item.id)
        }
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
    private let authenticationClient: any AuthenticationClient
    private let quranDataService: MobileSyncDataService
    private let noteService: MobileSyncNoteService
    private let ayahHighlightService: MobileSyncAyahHighlightService
    private let showHighlightsAction: () -> Void
    private let legacyImportPreferences = LegacyImportPreferences.shared
    private let notesPreferences = NotesPreferences.shared
    #else
    private let noteService: NoteService
    #endif
    private let textService: QuranTextDataService
    private let textRetriever: ShareableVerseTextRetriever
    private let navigateTo: (AyahNumber) -> Void
    private let editNoteAction: (Note) -> Void
    private let readingPreferences = ReadingPreferences.shared
    private var pendingDeletionIDs: Set<NoteItem.ID> = []

    #if QURAN_SYNC
    private func observeNotes() async {
        let notesSequence = readingPreferences.readings().flatMapLatest { [noteService] reading in
            noteService.notesSequence(quran: reading.quran)
        }
        do {
            for try await notes in notesSequence {
                self.notes = await noteItems(with: notes)
                    .filter { !pendingDeletionIDs.contains($0.id) }
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe notes: \(error)")
            self.error = error
        }
    }

    private func observeHighlights() async {
        let highlightsSequence = readingPreferences.readings().flatMapLatest { [ayahHighlightService] reading in
            ayahHighlightService.highlightsSequence(quran: reading.quran)
        }
        do {
            for try await highlights in highlightsSequence {
                self.highlights = highlights
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe highlights in Notes: \(error)")
        }
    }
    #endif

    private func restore(_ item: NoteItem, at index: Int) {
        notes.removeAll { $0.id == item.id }
        notes.insert(item, at: min(index, notes.endIndex))
    }

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

/// The user's highlights, for the Notes empty state.
struct NotesHighlightsSummary: Equatable {
    /// Up to four of the colors the user highlighted with.
    let colors: [HighlightColor]
    /// How many ayahs are highlighted, only for upgraders whose 3.0 notes held highlights.
    let upgraderCount: Int?
}
