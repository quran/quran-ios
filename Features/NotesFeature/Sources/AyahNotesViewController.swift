#if QURAN_SYNC
//
//  AyahNotesViewController.swift
//

import Combine
import NoorUI
import NoteEditorFeature
import QuranAnnotations
import SwiftUI
import UIKit
import UIx

@MainActor
final class AyahNotesViewController: UIHostingController<AyahNotesView>, NoteEditorListener {
    // MARK: Lifecycle

    init(
        viewModel: AyahNotesViewModel,
        noteEditorBuilder: NoteEditorBuilder,
        presentsNewNote: Bool,
        addAction: @escaping @MainActor @Sendable () -> Void,
        editAction: @escaping @MainActor @Sendable (Note) -> Void
    ) {
        self.viewModel = viewModel
        self.noteEditorBuilder = noteEditorBuilder
        shouldPresentNewNote = presentsNewNote
        super.init(rootView: AyahNotesView(
            viewModel: viewModel,
            addAction: addAction,
            editAction: editAction
        ))

        configureTitle()
        navigationItem.largeTitleDisplayMode = .never
        configureEditButton()
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard shouldPresentNewNote else {
            return
        }
        shouldPresentNewNote = false
        addNote()
    }

    func addNote() {
        presentNoteEditor(mode: .create(verses: viewModel.verses))
    }

    func editNote(_ note: Note) {
        presentNoteEditor(mode: .edit(note))
    }

    func dismissNoteEditor() {
        dismiss(animated: true)
    }

    // MARK: Private

    private let viewModel: AyahNotesViewModel
    private let noteEditorBuilder: NoteEditorBuilder
    private var shouldPresentNewNote: Bool
    private var editController: EditController?

    private var currentEditMode: EditMode? {
        viewModel.notes.isEmpty ? nil : viewModel.editMode
    }

    private func configureEditButton() {
        editController = EditController(
            navigationItem: navigationItem,
            reload: viewModel.objectWillChange.eraseToAnyPublisher(),
            editMode: Binding(
                get: { [weak self] in self?.currentEditMode },
                set: { [weak self] value in self?.viewModel.editMode = value ?? .inactive }
            )
        )
    }

    private func configureTitle() {
        guard let start = viewModel.verses.first, let end = viewModel.verses.last else {
            return
        }

        let title: MultipartText = "\(ayahRange: start ... end)"
        let label = UILabel()
        label.attributedText = title.attributedString(ofSize: .body)
        label.accessibilityLabel = title.accessibilityText
        navigationItem.titleView = label
    }

    private func presentNoteEditor(mode: NoteEditorMode) {
        let viewController = noteEditorBuilder.build(withListener: self, mode: mode)
        present(viewController, animated: true)
    }
}
#endif
