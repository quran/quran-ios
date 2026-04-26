#if QURAN_SYNC
    import AsyncAlgorithms
    import Combine
    import FeaturesSupport
    import Foundation
    import MobileSync
    import MobileSyncSupport
    import QuranAnnotations
    import QuranKit
    import QuranTextKit
    import ReadingService
    import SwiftUI
    import Utilities
    import VLogging

    @MainActor
    final class SyncedNotesViewModel: ObservableObject {
        // MARK: Lifecycle

        init(
            notesSyncService: NotesSyncService?,
            syncService: SyncService?,
            displayTextRetriever: DisplayVerseTextRetriever,
            shareableTextRetriever: ShareableVerseTextRetriever,
            navigateTo: @escaping (AyahNumber) -> Void
        ) {
            self.notesSyncService = notesSyncService
            self.syncService = syncService
            self.displayTextRetriever = displayTextRetriever
            self.shareableTextRetriever = shareableTextRetriever
            self.navigateTo = navigateTo
        }

        // MARK: Internal

        @Published var editMode: EditMode = .inactive
        @Published var error: Error? = nil
        @Published var notes: [SyncedNoteItem] = []

        func start() async {
            guard let syncService else {
                return
            }

            let quran = readingPreferences.reading.quran

            do {
                for try await (syncNotes, collections) in combineLatest(
                    syncService.notesSequence(),
                    HighlightCollection.updates(from: syncService)
                ) {
                    let notes = SyncedNoteReference.makeAll(from: syncNotes, quran: quran)
                    let colorsByVerse = HighlightCollection.highlightColorsByVerse(in: collections, quran: quran)
                    self.notes = await noteItems(with: notes, highlightColorsByVerse: colorsByVerse)
                        .sorted { $0.note.modifiedDate > $1.note.modifiedDate }
                }
            } catch is CancellationError {
            } catch {
                self.error = error
            }
        }

        func navigateTo(_ item: SyncedNoteItem) {
            guard let firstVerse = item.note.firstVerse else {
                return
            }
            logger.info("SyncedNotes: select note at \(firstVerse)")
            navigateTo(firstVerse)
        }

        func deleteItem(_ item: SyncedNoteItem) async {
            logger.info("SyncedNotes: delete note at \(String(describing: item.note.firstVerse))")
            do {
                if let localId = item.note.localId {
                    try await notesSyncService?.removeNote(localId: localId)
                }
            } catch {
                self.error = error
            }
        }

        func prepareNotesForSharing() async throws -> String {
            var notesText = [String]()
            let notes: [SyncedNoteItem] = await notes
            for (index, note) in notes.enumerated() {
                let title = note.note.body.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    notesText.append(contentsOf: [title, ""])
                }

                let verses = try await shareableTextRetriever.textForVerses(note.note.verses)
                notesText.append(contentsOf: verses)

                if index != notes.count - 1 {
                    notesText.append(contentsOf: ["", "", ""])
                }
            }
            return notesText.joined(separator: "\n")
        }

        // MARK: Private

        private let notesSyncService: NotesSyncService?
        private let syncService: SyncService?
        private let displayTextRetriever: DisplayVerseTextRetriever
        private let shareableTextRetriever: ShareableVerseTextRetriever
        private let navigateTo: (AyahNumber) -> Void
        private let readingPreferences = ReadingPreferences.shared

        private nonisolated func noteItems(
            with notes: [SyncedNoteReference],
            highlightColorsByVerse: [AyahNumber: HighlightColor]
        ) async -> [SyncedNoteItem] {
            await withTaskGroup(of: SyncedNoteItem.self) { group in
                for note in notes {
                    group.addTask {
                        do {
                            let verseText = try await self.displayTextRetriever.textForVerses(note.verses)
                            return SyncedNoteItem(
                                note: note,
                                verseText: verseText,
                                highlightColor: note.highlightColor(in: highlightColorsByVerse)
                            )
                        } catch {
                            let verseText = note.firstVerse?.localizedName ?? ""
                            return SyncedNoteItem(
                                note: note,
                                verseText: verseText,
                                highlightColor: note.highlightColor(in: highlightColorsByVerse)
                            )
                        }
                    }
                }

                return await group.collect()
            }
        }
    }
#endif
