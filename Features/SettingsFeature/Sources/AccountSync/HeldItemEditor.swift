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

/// Opens the editor that fixes a held item: the note editor for a note, the rename alert for a collection or a
/// reading bookmark.
@MainActor
final class HeldItemEditor: ObservableObject, NoteEditorListener {
    /// The held item is no longer on this device, such as a note deleted on another device since the list showed it.
    struct ItemNotFoundError: Error {}

    // MARK: Lifecycle

    init(
        noteService: MobileSyncNoteService,
        collectionService: AyahBookmarkCollectionService,
        readingBookmarkService: MobileSyncReadingBookmarkService,
        readingPreferences: ReadingPreferences,
        noteEditorBuilder: NoteEditorBuilder,
        navigationController: UINavigationController?
    ) {
        self.noteService = noteService
        self.collectionService = collectionService
        self.readingBookmarkService = readingBookmarkService
        self.readingPreferences = readingPreferences
        self.noteEditorBuilder = noteEditorBuilder
        self.navigationController = navigationController
    }

    // MARK: Internal

    @Published var nameAlert = CollectionNameAlert.hidden
    /// The reading bookmark the rename alert is for, or `nil` when it's hidden.
    @Published var renamingReadingBookmark: ReadingBookmarkSlot?
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
        case .readingBookmark(let slot, let name):
            logger.info("Quran Sync: renaming a held reading bookmark")
            pendingName = name
            renamingReadingBookmark = slot
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

    /// Renames the reading bookmark in `slot`; an empty name clears it, so the bookmark goes by its color.
    func renameReadingBookmark(in slot: ReadingBookmarkSlot) async {
        let name = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        let quran = readingPreferences.reading.quran
        do {
            // A rename stamps the bookmark as updated, so keeping its stored name, which another device may have
            // changed since the list showed it, must not write.
            let bookmarks = try await readingBookmarkService.readingBookmarksSequence(quran: quran).first { _ in true }
            try Task.checkCancellation()
            // The held list reads MobileSync directly and can show a bookmark this list drops, which still renames.
            if let current = bookmarks?.first(where: { $0.slot == slot }), name == (current.name ?? "") {
                return
            }
            try await readingBookmarkService.renameReadingBookmark(
                in: slot,
                name: name.isEmpty ? nil : name,
                quran: quran
            )
        } catch is CancellationError {
            return
        } catch {
            self.error = error
        }
    }

    func dismissNoteEditor() {
        navigationController?.dismiss(animated: true)
    }

    // MARK: Private

    private let noteService: MobileSyncNoteService
    private let collectionService: AyahBookmarkCollectionService
    private let readingBookmarkService: MobileSyncReadingBookmarkService
    private let readingPreferences: ReadingPreferences
    private let noteEditorBuilder: NoteEditorBuilder
    private weak var navigationController: UINavigationController?
    private var renamingCollectionID: String?

    private func editNote(id: String) async {
        logger.info("Quran Sync: editing a held note")
        do {
            let notes = try await noteService.notesSequence(quran: readingPreferences.reading.quran).first { _ in true }
            try Task.checkCancellation()
            guard let note = notes?.first(where: { $0.id == id }) else {
                logger.error("Quran Sync: the held note to edit is no longer on this device")
                error = ItemNotFoundError()
                return
            }
            let viewController = noteEditorBuilder.build(withListener: self, mode: .edit(note))
            navigationController?.present(viewController, animated: true)
        } catch is CancellationError {
            return
        } catch {
            self.error = error
        }
    }
}
#endif
