//
//  NotesViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

#if !QURAN_SYNC
import Analytics
import Combine
#else
import Analytics
import AuthenticationClient
import FeaturesSupport
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
import UIKit
import UIx
import Utilities
import VLogging

@MainActor
final class NotesViewModel: ObservableObject {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        analytics: AnalyticsLibrary,
        authenticationClient: any AuthenticationClient,
        navigationController: UINavigationController,
        noteService: MobileSyncNoteService,
        textService: QuranTextDataService,
        textRetriever: ShareableVerseTextRetriever,
        quranFontSource: QuranFontSource,
        navigateTo: @escaping (AyahNumber) -> Void,
        editNote: @escaping (Note) -> Void
    ) {
        self.analytics = analytics
        self.authenticationClient = authenticationClient
        self.navigationController = navigationController
        self.noteService = noteService
        self.textService = textService
        self.textRetriever = textRetriever
        quranFont = quranFontSource.current
        self.navigateTo = navigateTo
        editNoteAction = editNote
        isSyncBannerDismissed = preferences.isNotesSyncBannerDismissed
        quranFontSource.updates
            .assign(to: &$quranFont)
    }
    #else
    init(
        analytics: AnalyticsLibrary,
        noteService: NoteService,
        textRetriever: ShareableVerseTextRetriever,
        textService: QuranTextDataService,
        quranFontSource: QuranFontSource,
        navigateTo: @escaping (AyahNumber) -> Void,
        editNote: @escaping (Note) -> Void
    ) {
        self.analytics = analytics
        self.noteService = noteService
        self.textRetriever = textRetriever
        self.textService = textService
        quranFont = quranFontSource.current
        self.navigateTo = navigateTo
        editNoteAction = editNote
        quranFontSource.updates
            .assign(to: &$quranFont)
    }
    #endif

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    #if QURAN_SYNC
    @Published var isAuthenticated = false
    @Published var isSyncBannerDismissed: Bool
    #endif
    @Published var notes: [NoteItem] = []
    @Published var searchTerm: String = ""
    @Published var quranFont: QuranFont

    #if QURAN_SYNC
    var shouldShowSyncBanner: Bool {
        !isAuthenticated && !isSyncBannerDismissed
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
            let suraName = item.note.startAyah.sura.localizedName()
            return suraName.range(of: term, options: .caseInsensitive) != nil
        }
    }

    func start() async {
        #if QURAN_SYNC
        isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated
        logger.info("Quran Sync: restored authentication from Notes. Authenticated: \(isAuthenticated)")
        do {
            let sequence = noteService.notesSequence(quran: readingPreferences.reading.quran)
            for try await notes in sequence {
                self.notes = await noteItems(with: notes)
                    .filter { !pendingDeletionIDs.contains($0.id) }
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe notes: \(error)")
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
                .filter { !pendingDeletionIDs.contains($0.id) }
                .sorted { $0.note.modifiedDate > $1.note.modifiedDate }
        }
        #endif
    }

    #if QURAN_SYNC
    func loginToQuranCom() async {
        guard let navigationController else {
            return
        }

        analytics.quranSyncSignIn(from: .notes)
        logger.info("Quran Sync: starting sign in from Notes")
        do {
            try await authenticationClient.login(on: navigationController)
            isAuthenticated = await authenticationClient.authenticationState == .authenticated
            logger.info("Quran Sync: sign in completed from Notes. Authenticated: \(isAuthenticated)")
        } catch AuthenticationClientError.cancelled {
            logger.info("Quran Sync: sign in cancelled from Notes")
            return
        } catch {
            logger.error("Failed to login to Quran.com from notes: \(error)")
            self.error = error
        }
    }

    func dismissSyncBanner() {
        analytics.quranSyncSignInBannerDismissed(from: .notes)
        logger.info("Quran Sync: sign-in banner dismissed from Notes")
        isSyncBannerDismissed = true
        preferences.isNotesSyncBannerDismissed = true
    }
    #endif

    func navigateTo(_ item: NoteItem) {
        logger.info("Notes: select note at \(item.note.startAyah)")
        navigateTo(item.note.startAyah)
    }

    func editNote(_ item: NoteItem) {
        logger.info("Notes: edit note at \(item.note.startAyah)")
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
            logger.info("Notes: delete note at \(item.note.startAyah)")
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

    private let analytics: AnalyticsLibrary
    #if QURAN_SYNC
    private let authenticationClient: any AuthenticationClient
    private let noteService: MobileSyncNoteService
    private weak var navigationController: UINavigationController?
    private let preferences = AuthenticationPreferences.shared
    #else
    private let noteService: NoteService
    #endif
    private let textService: QuranTextDataService
    private let textRetriever: ShareableVerseTextRetriever
    private let navigateTo: (AyahNumber) -> Void
    private let editNoteAction: (Note) -> Void
    private let readingPreferences = ReadingPreferences.shared
    private var pendingDeletionIDs: Set<NoteItem.ID> = []

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
