#if QURAN_SYNC
    import Crashing
    import FeaturesSupport
    import Foundation
    import MobileSyncSupport
    import NoorUI
    import QuranAnnotations
    import QuranTextKit
    import VLogging

    @MainActor
    final class SyncedNoteEditorInteractor {
        // MARK: Lifecycle

        init(
            notesSyncService: NotesSyncService?,
            textRetriever: ShareableVerseTextRetriever,
            note: SyncedNoteReference
        ) {
            self.notesSyncService = notesSyncService
            self.textRetriever = textRetriever
            self.note = note
        }

        // MARK: Internal

        weak var listener: NoteEditorListener?

        var isEditedNote: Bool {
            !(editableNote?.note ?? note.body).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var hasPersistedNote: Bool {
            note.localId != nil
        }

        func fetchNote() async throws -> EditableNote {
            do {
                let versesText = try await textRetriever.textForVerses(note.verses)
                let editableNote = EditableNote(
                    ayahText: versesText.joined(separator: "\n"),
                    modifiedSince: note.modifiedDate.timeAgo(),
                    selectedColor: .red,
                    note: note.body
                )
                self.editableNote = editableNote
                logger.info("SyncedNoteEditor: note loaded")
                return editableNote
            } catch {
                crasher.recordError(error, reason: "Failed to retrieve sync note text")
                throw error
            }
        }

        func commitEditsAndExist() async {
            logger.info("SyncedNoteEditor: done tapped")
            let body = (editableNote?.note ?? note.body).trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                if body.isEmpty {
                    if let localId = note.localId {
                        try await notesSyncService?.removeNote(localId: localId)
                    }
                } else if let localId = note.localId {
                    try await notesSyncService?.updateNote(localId: localId, body: body, verses: note.versesSet)
                } else {
                    try await notesSyncService?.createNote(body: body, verses: note.versesSet)
                }
                logger.info("SyncedNoteEditor: note saved")
                listener?.dismissNoteEditor()
            } catch {
                crasher.recordError(error, reason: "Failed to save sync note")
            }
        }

        func forceDelete() async {
            logger.info("SyncedNoteEditor: force delete note")
            do {
                if let localId = note.localId {
                    try await notesSyncService?.removeNote(localId: localId)
                }
                listener?.dismissNoteEditor()
            } catch {
                crasher.recordError(error, reason: "Failed to delete sync note")
            }
        }

        // MARK: Private

        private let notesSyncService: NotesSyncService?
        private let textRetriever: ShareableVerseTextRetriever
        private let note: SyncedNoteReference

        private var editableNote: EditableNote?
    }
#endif
