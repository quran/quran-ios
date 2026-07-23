//
//  NoteEditorViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Analytics
import AnnotationsService
import Crashing
import Foundation
import NoorUI
import QuranAnnotations
import QuranKit
import QuranTextKit
import VLogging

@MainActor
public protocol NoteEditorListener: AnyObject {
    func dismissNoteEditor()
}

@MainActor
final class NoteEditorViewModel {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        noteService: MobileSyncNoteService,
        analytics: AnalyticsLibrary,
        mode: NoteEditorMode,
        textService: QuranTextDataService
    ) {
        self.noteService = noteService
        self.analytics = analytics
        self.mode = mode
        self.textService = textService
    }
    #else
    init(
        noteService: NoteEditorLegacyServicing,
        note: Note,
        textService: QuranTextDataService
    ) {
        self.note = note
        self.noteService = noteService
        self.textService = textService
    }
    #endif

    // MARK: Internal

    enum DeleteConfirmationStyle: Equatable {
        case note
        case syncedNote
    }

    static let minimumNoteBodyLength = 6

    weak var listener: NoteEditorListener?

    var minimumNoteBodyLength: Int { Self.minimumNoteBodyLength }

    var showsColors: Bool {
        #if QURAN_SYNC
        return false
        #else
        return true
        #endif
    }

    var deleteConfirmationStyle: DeleteConfirmationStyle {
        #if QURAN_SYNC
        return .syncedNote
        #else
        return .note
        #endif
    }

    var hasNoteText: Bool {
        !trimmedNoteText.isEmpty
    }

    var canSubmitNote: Bool {
        trimmedNoteText.count >= minimumNoteBodyLength
    }

    var canDismissNote: Bool {
        !hasNoteText || canSubmitNote
    }

    var shouldAutoSaveOnDismiss: Bool {
        canSubmitNote
    }

    func fetchNote() async throws -> EditableNote {
        do {
            let versesText = try await getTextForVerses(verses)
            guard let versesRange else {
                throw NoteEditorError.noVerses
            }
            logger.info("NoteEditor: note loaded")
            let editableNote = EditableNote(
                ayahRange: versesRange.start ... versesRange.end,
                ayahText: versesText,
                modifiedSince: modifiedSince,
                selectedColor: selectedColor,
                note: body
            )
            self.editableNote = editableNote
            return editableNote
        } catch {
            crasher.recordError(error, reason: "Failed to retrieve note text")
            throw error
        }
    }

    @discardableResult
    func commitEditsAndExit(dismissOnSave: Bool) async -> Bool {
        logger.info("NoteEditor: done tapped")
        #if QURAN_SYNC
        guard hasNoteText else {
            if dismissOnSave {
                listener?.dismissNoteEditor()
            }
            return dismissOnSave
        }
        #else
        guard hasNoteText || dismissOnSave else {
            return false
        }
        #endif

        guard !hasNoteText || canSubmitNote else {
            return false
        }

        do {
            #if QURAN_SYNC
            guard let range = versesRange else {
                return false
            }
            analytics.logEvent("UpdateNoteVersesNum", value: Set(verses).count.description)
            switch mode {
            case .create:
                try await noteService.createNote(body: noteText, startAyah: range.start, endAyah: range.end)
            case .edit(let note):
                try await noteService.updateNote(note, body: noteText, startAyah: range.start, endAyah: range.end)
            }
            #else
            try await noteService.setNote(
                noteText,
                verses: note.verses,
                color: editableNote?.selectedColor ?? note.color
            )
            #endif
            logger.info("NoteEditor: note saved")
            if dismissOnSave {
                listener?.dismissNoteEditor()
            }
            return true
        } catch {
            crasher.recordError(error, reason: "Failed to set note")
            return false
        }
    }

    func forceDelete() async {
        logger.info("NoteEditor: force delete note")
        #if QURAN_SYNC
        guard case .edit(let note) = mode else {
            listener?.dismissNoteEditor()
            return
        }
        #endif

        do {
            #if QURAN_SYNC
            try await noteService.removeNote(note)
            #else
            try await noteService.removeNotes(with: Array(note.verses))
            #endif
            logger.info("NoteEditor: notes removed")
            listener?.dismissNoteEditor()
        } catch {
            crasher.recordError(error, reason: "Failed to delete note")
        }
    }

    // MARK: Private

    #if QURAN_SYNC
    private let noteService: MobileSyncNoteService
    private let analytics: AnalyticsLibrary
    private let mode: NoteEditorMode
    #else
    private let noteService: NoteEditorLegacyServicing
    private let note: Note
    #endif
    private let textService: QuranTextDataService

    private var editableNote: EditableNote?

    private var noteText: String {
        editableNote?.note ?? body
    }

    private var trimmedNoteText: String {
        noteText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedColor: HighlightColor {
        #if QURAN_SYNC
        return .red
        #else
        return note.color
        #endif
    }

    private var verses: [AyahNumber] {
        #if QURAN_SYNC
        switch mode {
        case .create(let verses):
            return verses
        case .edit(let note):
            return note.startAyah.array(to: note.endAyah)
        }
        #else
        return Array(note.verses)
        #endif
    }

    private var versesRange: (start: AyahNumber, end: AyahNumber)? {
        let verses = verses.sorted()
        guard let start = verses.first, let end = verses.last else {
            return nil
        }
        return (start, end)
    }

    private var body: String {
        #if QURAN_SYNC
        switch mode {
        case .create:
            return ""
        case .edit(let note):
            return note.text
        }
        #else
        return note.text ?? ""
        #endif
    }

    private var modifiedSince: String {
        #if QURAN_SYNC
        switch mode {
        case .create:
            return ""
        case .edit(let note):
            return note.modifiedDate.timeAgo()
        }
        #else
        return note.modifiedDate.timeAgo()
        #endif
    }

    private func getTextForVerses(_ verses: [AyahNumber]) async throws -> String {
        try await textService.numberedArabicText(for: verses)
    }
}

#if !QURAN_SYNC
protocol NoteEditorLegacyServicing {
    func setNote(_ note: String, verses: [AyahNumber], color: HighlightColor) async throws
    func removeNotes(with verses: [AyahNumber]) async throws
}

extension NoteService: NoteEditorLegacyServicing {}
#endif

private enum NoteEditorError: Error {
    case noVerses
}
