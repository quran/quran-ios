#if QURAN_SYNC
//
//  HeldItemEditor.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import AnnotationsService
import Foundation
import NoorUI
import NoteEditorFeature
import QuranAnnotations
import ReadingService
import UIKit
import VLogging

/// Opens the editor that fixes a held item: the note editor for a note, the rename alert for a collection.
@MainActor
final class HeldItemEditor: ObservableObject, NoteEditorListener {
    // MARK: Lifecycle

    init(
        noteService: MobileSyncNoteService,
        collectionService: AyahBookmarkCollectionService,
        noteEditorBuilder: NoteEditorBuilder,
        navigationController: UINavigationController?
    ) {
        self.noteService = noteService
        self.collectionService = collectionService
        self.noteEditorBuilder = noteEditorBuilder
        self.navigationController = navigationController
    }

    // MARK: Internal

    @Published var nameAlert = CollectionNameAlert.hidden
    @Published var pendingName = ""
    @Published var error: Error?

    func edit(_ edit: HeldItemRow.Edit) async {
        switch edit {
        case .note(let id):
            await editNote(id: id)
        case .collection(let id, let name):
            logger.info("Quran Sync: renaming a held collection")
            renamingCollectionID = id
            pendingName = name
            nameAlert = .editing
        }
    }

    func renamePending() async {
        guard let renamingCollectionID else {
            return
        }
        let name = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        do {
            try await collectionService.renameCollection(id: renamingCollectionID, to: name)
            nameAlert = .hidden
            self.renamingCollectionID = nil
        } catch {
            if let nameError = CollectionNameError(error) {
                logger.info("Quran Sync: held collection name rejected. \(nameError.logDescription)")
                nameAlert = .rejected(nameError)
            } else {
                self.error = error
            }
        }
    }

    func dismissNoteEditor() {
        navigationController?.dismiss(animated: true)
    }

    // MARK: Private

    private let noteService: MobileSyncNoteService
    private let collectionService: AyahBookmarkCollectionService
    private let noteEditorBuilder: NoteEditorBuilder
    private weak var navigationController: UINavigationController?
    private var renamingCollectionID: String?

    private func editNote(id: String) async {
        logger.info("Quran Sync: editing a held note")
        do {
            guard let note = try await currentNotes().first(where: { $0.id == id }) else {
                return
            }
            let viewController = noteEditorBuilder.build(withListener: self, mode: .edit(note))
            navigationController?.present(viewController, animated: true)
        } catch {
            self.error = error
        }
    }

    /// The notes now. Cancelling the observing task, rather than breaking out of the loop, stops MobileSync's
    /// collector.
    private func currentNotes() async throws -> [Note] {
        let sequence = noteService.notesSequence(quran: ReadingPreferences.shared.reading.quran)
        let task = Task { () throws -> [Note] in
            var first: [Note] = []
            do {
                for try await notes in sequence {
                    first = notes
                    withUnsafeCurrentTask { $0?.cancel() }
                }
            } catch is CancellationError {}
            return first
        }
        return try await task.value
    }
}
#endif
