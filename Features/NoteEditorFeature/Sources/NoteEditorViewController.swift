//
//  NoteEditorViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import NoorUI
import SwiftUI
import UIKit
import VLogging

final class NoteEditorViewController: BaseViewController, UIAdaptivePresentationControllerDelegate {
    // MARK: Lifecycle

    init(viewModel: NoteEditorViewModel) {
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

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        viewModel.canDismissNote
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showMinimumLengthAlert()
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard !suppressesDismissalAutoSave, viewModel.shouldAutoSaveOnDismiss else {
            return
        }

        Task {
            await viewModel.commitEditsAndExit(dismissOnSave: false)
        }
    }

    // MARK: Private

    private let viewModel: NoteEditorViewModel
    private var suppressesDismissalAutoSave = false

    private func setNote(_ note: EditableNote) {
        let noteEditor = NoteEditorView(
            note: note,
            showsColors: viewModel.showsColors,
            done: { [weak self] in self?.done() },
            delete: { [weak self] in await self?.delete() }
        )
        let viewController = UIHostingController(rootView: noteEditor)
        let navigationController = buildNavigationController(rootViewController: viewController, note: note)
        addFullScreenChild(navigationController)
    }

    private func buildNavigationController(rootViewController: UIViewController, note: EditableNote) -> UINavigationController {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        let title: MultipartText = "\(ayahRange: note.ayahRange)"
        let titleLabel = UILabel()
        titleLabel.attributedText = title.attributedString(ofSize: .body)
        titleLabel.accessibilityLabel = title.accessibilityText
        titleLabel.adjustsFontForContentSizeCategory = true

        rootViewController.navigationItem.largeTitleDisplayMode = .never
        rootViewController.navigationItem.titleView = titleLabel
        rootViewController.navigationItem.rightBarButtonItem = doneButton

        let navigationController = UINavigationController(rootViewController: rootViewController)
        let themeStyle = ThemeService.shared.themeStyle
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = themeStyle.backgroundColor
        appearance.shadowColor = .clear

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = .appIdentity
        navigationController.view.backgroundColor = themeStyle.backgroundColor
        return navigationController
    }

    @objc
    private func doneTapped() {
        done()
    }

    private func done() {
        guard viewModel.canDismissNote else {
            showMinimumLengthAlert()
            return
        }

        suppressesDismissalAutoSave = true
        Task {
            let didSave = await viewModel.commitEditsAndExit(dismissOnSave: true)
            if !didSave {
                suppressesDismissalAutoSave = false
            }
        }
    }

    private func delete() async {
        logger.info("NoteEditor: delete note")
        if viewModel.hasNoteText {
            logger.info("NoteEditor: confirm note deletion")
            confirmDeleteNote()
        } else {
            // delete highlight
            suppressesDismissalAutoSave = true
            await viewModel.forceDelete()
        }
    }

    private func confirmDeleteNote() {
        let delete = {
            self.suppressesDismissalAutoSave = true
            await self.viewModel.forceDelete()
        }
        switch viewModel.deleteConfirmationStyle {
        case .note:
            confirmNoteDelete(delete: delete, cancel: { })
        case .syncedNote:
            confirmSyncedNoteDelete(delete: delete, cancel: { })
        }
    }

    private func showMinimumLengthAlert() {
        showNoteMinimumLengthAlert(minimumLength: viewModel.minimumNoteBodyLength)
    }
}
