#if QURAN_SYNC
    //
    //  SyncedNoteEditorInteractor.swift
    //
    //  Created by Ahmed Nabil on 2026-05-16.
    //

    import AnnotationsService
    import Crashing
    import Foundation
    import NoorUI
    import QuranAnnotations
    import QuranKit
    import VLogging

    @MainActor
    final class SyncedNoteEditorInteractor {
        // MARK: Lifecycle

        init(noteService: MobileSyncNoteService, mode: Mode) {
            self.noteService = noteService
            self.mode = mode
        }

        // MARK: Internal

        enum Mode {
            case create(verses: [AyahNumber])
            case edit(SyncedNote)
        }

        weak var listener: NoteEditorListener?

        var minimumNoteBodyLength: Int { MobileSyncNoteService.minimumBodyLength }

        var isEditedNote: Bool {
            !(editableNote?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var canSubmitNote: Bool {
            let text = (editableNote?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return !text.isEmpty && text.count >= minimumNoteBodyLength
        }

        func fetchNote() async throws -> EditableNote {
            do {
                let versesText = try await noteService.textForVerses(verses)
                let editableNote = EditableNote(
                    ayahText: versesText,
                    modifiedSince: modifiedSince,
                    selectedColor: .red,
                    note: body
                )
                self.editableNote = editableNote
                return editableNote
            } catch {
                crasher.recordError(error, reason: "Failed to retrieve synced note text")
                throw error
            }
        }

        func commitEditsAndExit() async {
            logger.info("SyncedNoteEditor: done tapped")
            do {
                let body = editableNote?.note ?? body
                switch mode {
                case .create:
                    try await noteService.createNote(body: body, verses: verses)
                case .edit(let note):
                    try await noteService.updateNote(note, body: body)
                }
                listener?.dismissNoteEditor()
            } catch {
                crasher.recordError(error, reason: "Failed to save synced note")
            }
        }

        func forceDelete() async {
            guard case .edit(let note) = mode else {
                listener?.dismissNoteEditor()
                return
            }

            do {
                try await noteService.removeNote(note)
                listener?.dismissNoteEditor()
            } catch {
                crasher.recordError(error, reason: "Failed to delete synced note")
            }
        }

        // MARK: Private

        private let noteService: MobileSyncNoteService
        private let mode: Mode
        private var editableNote: EditableNote?

        private var verses: [AyahNumber] {
            switch mode {
            case .create(let verses):
                return verses
            case .edit(let note):
                return note.verses
            }
        }

        private var body: String {
            switch mode {
            case .create:
                return ""
            case .edit(let note):
                return note.body
            }
        }

        private var modifiedSince: String {
            switch mode {
            case .create:
                return ""
            case .edit(let note):
                return note.modifiedDate.timeAgo()
            }
        }
    }
#endif
