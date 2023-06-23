//
//  NoteEditorInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AnnotationsService
import Crashing
import Foundation
import NoorUI
import QuranAnnotations
import QuranTextKit
import Utilities
import VLogging

@MainActor
public protocol NoteEditorListener: AnyObject {
    func dismissNoteEditor()
}

@MainActor
final class NoteEditorInteractor {
    // MARK: Lifecycle

    init(noteService: NoteService, note: Note) {
        self.note = note
        self.noteService = noteService
    }

    // MARK: Internal

    weak var listener: NoteEditorListener?

    var isEditedNote: Bool {
        !(editbleNote?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func fetchNote() async throws -> EditableNote {
        do {
            let versesText = try await getNoteText()

            logger.info("NoteEditor: note loaded")
            let editbleNote = EditableNote(
                ayahText: versesText,
                modifiedSince: note.modifiedDate.timeAgo(),
                selectedColor: note.color,
                note: note.note ?? ""
            )
            self.editbleNote = editbleNote
            return editbleNote
        } catch {
            crasher.recordError(error, reason: "Failed to retrieve note text")
            throw error
        }
    }

    func commitEditsAndExist() async {
        logger.info("NoteEditor: done tapped")
        let editorColor = editbleNote?.selectedColor
        do {
            try await noteService.setNote(
                editbleNote?.note ?? note.note ?? "",
                verses: note.verses,
                color: editorColor ?? note.color
            )
            logger.info("NoteEditor: note saved")
            listener?.dismissNoteEditor()
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to set note")
        }
    }

    func forceDelete() async {
        logger.info("NoteEditor: force delete note")
        do {
            try await noteService.removeNotes(with: Array(note.verses))
            logger.info("NoteEditor: notes removed")
            listener?.dismissNoteEditor()
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to delete note")
        }
    }

    // MARK: Private

    private let noteService: NoteService
    private let note: Note

    private var editbleNote: EditableNote?

    // MAKR: - Helpers

    private func getNoteText() async throws -> String {
        try await noteService.textForVerses(Array(note.verses))
    }
}
