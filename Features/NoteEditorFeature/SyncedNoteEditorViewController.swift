#if QURAN_SYNC
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

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            guard !isCompleting else {
                return
            }
            done()
        }

        // MARK: Private

        private let viewModel: SyncedNoteEditorInteractor
        private var currentNote: EditableNote?
        private var doneButton: UIBarButtonItem?
        private var noteCancellable: AnyCancellable?
        private var isCompleting = false

        private func setNote(_ note: EditableNote) {
            currentNote = note
            observe(note)

            let noteEditor = NoteEditorView(
                note: note,
                done: { [weak self] in self?.done() },
                delete: { [weak self] in await self?.delete() },
                style: .sync
            )
            let viewController = UIHostingController(rootView: noteEditor)
            let navigationController = buildNavigationController(rootViewController: viewController, note: note)
            addFullScreenChild(navigationController)
            updateDoneButtonState()
        }

        private func buildNavigationController(rootViewController: UIViewController, note: EditableNote) -> UINavigationController {
            let modifiedText = UIBarButtonItem(title: note.modifiedSince, style: .plain, target: nil, action: nil)
            modifiedText.isEnabled = false
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
            self.doneButton = doneButton

            rootViewController.navigationItem.largeTitleDisplayMode = .never
            rootViewController.navigationItem.leftBarButtonItem = modifiedText
            rootViewController.navigationItem.rightBarButtonItem = doneButton

            return UINavigationController(rootViewController: rootViewController)
        }

        private func observe(_ note: EditableNote) {
            noteCancellable = note.objectWillChange.sink { [weak self] in
                DispatchQueue.main.async {
                    self?.updateDoneButtonState()
                }
            }
        }

        private func updateDoneButtonState() {
            let trimmedText = currentNote?.note.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            doneButton?.isEnabled = !trimmedText.isEmpty
        }

        @objc
        private func doneTapped() {
            done()
        }

        private func done() {
            guard !isCompleting else {
                return
            }
            isCompleting = true

            Task {
                do {
                    try await viewModel.commitEditsAndExit()
                } catch {
                    isCompleting = false
                    showErrorAlert(error: error)
                }
            }
        }

        private func delete() async {
            logger.info("SyncedNoteEditor: delete note")
            if viewModel.hasPersistedNote, viewModel.isEditedNote {
                logger.info("SyncedNoteEditor: confirm note deletion")
                confirmNoteDelete(
                    delete: {
                        do {
                            try await self.viewModel.forceDelete()
                        } catch {
                            self.showErrorAlert(error: error)
                        }
                    },
                    cancel: { }
                )
            } else if viewModel.hasPersistedNote {
                do {
                    try await viewModel.forceDelete()
                } catch {
                    showErrorAlert(error: error)
                }
            } else {
                dismiss(animated: true)
            }
        }
    }
#endif
