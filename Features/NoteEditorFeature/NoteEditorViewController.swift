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

    init(viewModel: NoteEditorInteractor) {
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
                // TODO: should show error to the user
            }
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        done()
    }

    // MARK: Private

    private let viewModel: NoteEditorInteractor

    private func setNote(_ note: EditableNote) {
        let noteEditor = NoteEditorView(
            note: note,
            done: { [weak self] in self?.done() },
            delete: { [weak self] in self?.delete() }
        )
        let viewController = UIHostingController(rootView: noteEditor)
        let navigationController = buildNavigationController(rootViewController: viewController, note: note)
        addFullScreenChild(navigationController)
    }

    private func buildNavigationController(rootViewController: UIViewController, note: EditableNote) -> UINavigationController {
        let modifiedText = UIBarButtonItem(title: note.modifiedSince, style: .plain, target: nil, action: nil)
        modifiedText.isEnabled = false
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        rootViewController.navigationItem.largeTitleDisplayMode = .never
        rootViewController.navigationItem.leftBarButtonItem = modifiedText
        rootViewController.navigationItem.rightBarButtonItem = doneButton

        let navigationController = UINavigationController(rootViewController: rootViewController)
        return navigationController
    }

    @objc
    private func doneTapped() {
        done()
    }

    private func done() {
        viewModel.done()
    }

    private func delete() {
        logger.info("NoteEditor: delete note")
        if viewModel.isEditedNote {
            logger.info("NoteEditor: confirm note deletion")
            confirmNoteDelete(
                delete: { self.viewModel.forceDelete() },
                cancel: { }
            )
        } else {
            // delete highlight
            viewModel.forceDelete()
        }
    }
}
