#if QURAN_SYNC
//
//  SyncedNoteEditorViewController.swift
//
//  Created by Ahmed Nabil on 2026-05-16.
//

import Combine
import NoorUI
import SwiftUI
import UIKit
import VLogging

final class SyncedNoteEditorViewController: BaseViewController, UIAdaptivePresentationControllerDelegate {
    // MARK: Lifecycle

    init(viewModel: SyncedNoteEditorInteractor) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationController?.delegate = self

        Task {
            do {
                let note = try await viewModel.fetchNote()
                setNote(note)
            } catch {
                showErrorAlert(error: error)
            }
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {}

    // MARK: Private

    private let viewModel: SyncedNoteEditorInteractor
    private var doneButton: UIBarButtonItem?
    private var cancellables: Set<AnyCancellable> = []

    private func setNote(_ note: EditableNote) {
        let noteEditor = NoteEditorView(
            note: note,
            showsColors: false,
            done: { [weak self] in self?.doneTapped() },
            delete: { [weak self] in await self?.delete() }
        )
        let viewController = UIHostingController(rootView: noteEditor)
        let navigationController = buildNavigationController(rootViewController: viewController, note: note)
        bindDoneButton(to: note)
        addFullScreenChild(navigationController)
    }

    private func buildNavigationController(rootViewController: UIViewController, note: EditableNote) -> UINavigationController {
        let modifiedText = UIBarButtonItem(title: note.modifiedSince, style: .plain, target: nil, action: nil)
        modifiedText.isEnabled = false
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        rootViewController.navigationItem.largeTitleDisplayMode = .never
        rootViewController.navigationItem.leftBarButtonItem = modifiedText
        rootViewController.navigationItem.rightBarButtonItem = doneButton
        self.doneButton = doneButton

        return UINavigationController(rootViewController: rootViewController)
    }

    private func bindDoneButton(to note: EditableNote) {
        updateDoneButton(text: note.note)
        note.notePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.updateDoneButton(text: text) }
            .store(in: &cancellables)
    }

    private func updateDoneButton(text: String) {
        doneButton?.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @objc
    private func doneTapped() {
        guard viewModel.canSubmitNote else {
            showNoteMinimumLengthAlert(minimumLength: viewModel.minimumNoteBodyLength)
            return
        }

        Task {
            await viewModel.commitEditsAndExit()
        }
    }

    private func delete() async {
        logger.info("SyncedNoteEditor: delete note")
        if viewModel.isEditedNote {
            confirmSyncedNoteDelete(
                delete: { await self.viewModel.forceDelete() },
                cancel: { }
            )
        } else {
            await viewModel.forceDelete()
        }
    }
}
#endif
