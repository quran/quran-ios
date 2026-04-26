#if QURAN_SYNC
    import FeaturesSupport
    import Foundation
    import MobileSyncSupport
    import NoorUI
    import VLogging

    @MainActor
    final class SyncedNoteEditorInteractor {
        // MARK: Lifecycle

        init(
            notesSyncService: NotesSyncService?,
            textRetriever: DisplayVerseTextRetriever,
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
            let versesText = try await textRetriever.textForVerses(note.verses)
            let editableNote = EditableNote(
                ayahText: versesText,
                modifiedSince: note.modifiedDate.timeAgo(),
                selectedColor: .red,
                note: note.body
            )
            self.editableNote = editableNote
            logger.info("SyncedNoteEditor: note loaded")
            return editableNote
        }

        func commitEditsAndExit() async throws {
            logger.info("SyncedNoteEditor: done tapped")
            let body = (editableNote?.note ?? note.body).trimmingCharacters(in: .whitespacesAndNewlines)
            if body.isEmpty {
                if let localId = note.localId {
                    try await notesSyncService?.removeNote(localId: localId)
                }
            } else if let localId = note.localId {
                if let startVerse = note.verses.first, let endVerse = note.verses.last {
                    try await notesSyncService?.updateNote(localId: localId, body: body, startVerse: startVerse, endVerse: endVerse)
                }
            } else {
                if let startVerse = note.verses.first, let endVerse = note.verses.last {
                    try await notesSyncService?.createNote(body: body, startVerse: startVerse, endVerse: endVerse)
                }
            }

            logger.info("SyncedNoteEditor: note saved")
            listener?.dismissNoteEditor()
        }

        func forceDelete() async throws {
            logger.info("SyncedNoteEditor: force delete note")
            if let localId = note.localId {
                try await notesSyncService?.removeNote(localId: localId)
            }
            listener?.dismissNoteEditor()
        }

        // MARK: Private

        private let notesSyncService: NotesSyncService?
        private let textRetriever: DisplayVerseTextRetriever
        private let note: SyncedNoteReference

        private var editableNote: EditableNote?
    }
#endif
