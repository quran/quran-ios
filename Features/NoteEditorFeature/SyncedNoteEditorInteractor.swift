#if QURAN_SYNC
//
//  SyncedNoteEditorInteractor.swift
//
//  Created by Ahmed Nabil on 2026-05-16.
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
final class SyncedNoteEditorInteractor {
    // MARK: Lifecycle

    init(noteService: MobileSyncNoteService, textService: QuranTextDataService, analytics: AnalyticsLibrary, mode: Mode) {
        self.noteService = noteService
        self.textService = textService
        self.analytics = analytics
        self.mode = mode
    }

    // MARK: Internal

    enum Mode {
        case create(verses: [AyahNumber])
        case edit(SyncedNote)
    }

    static let minimumNoteBodyLength = 6

    weak var listener: NoteEditorListener?

    var minimumNoteBodyLength: Int { Self.minimumNoteBodyLength }

    var isEditedNote: Bool {
        !(editableNote?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSubmitNote: Bool {
        let text = (editableNote?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.isEmpty && text.count >= minimumNoteBodyLength
    }

    func fetchNote() async throws -> EditableNote {
        do {
            let versesText = try await textForVerses(verses)
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
            guard let range = versesRange else {
                return
            }
            analytics.logEvent("UpdateNoteVersesNum", value: Set(verses).count.description)
            switch mode {
            case .create:
                try await noteService.createNote(body: body, startAyah: range.start, endAyah: range.end)
            case .edit(let note):
                try await noteService.updateNote(note, body: body, startAyah: range.start, endAyah: range.end)
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
    private let textService: QuranTextDataService
    private let analytics: AnalyticsLibrary
    private let mode: Mode
    private var editableNote: EditableNote?

    private var verses: [AyahNumber] {
        switch mode {
        case .create(let verses):
            return verses
        case .edit(let note):
            return note.startAyah.array(to: note.endAyah)
        }
    }

    private var versesRange: (start: AyahNumber, end: AyahNumber)? {
        let verses = verses.sorted()
        guard let start = verses.first, let end = verses.last else {
            return nil
        }
        return (start, end)
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

    private func textForVerses(_ verses: [AyahNumber]) async throws -> String {
        let verseTexts = try await textService.textForVerses(verses, translations: [])
        return verses.sorted()
            .compactMap { verse in
                verseTexts[verse].map { $0.arabicText + " \(NumberFormatter.arabicNumberFormatter.format(verse.ayah))" }
            }
            .joined(separator: " ")
    }
}
#endif
