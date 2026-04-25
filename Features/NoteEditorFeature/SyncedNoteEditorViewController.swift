#if QURAN_SYNC
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
                }
            }
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            done()
        }

        // MARK: Private

        private let viewModel: SyncedNoteEditorInteractor

        private func setNote(_ note: EditableNote) {
            let noteEditor = NoteEditorView(
                note: note,
                done: { [weak self] in self?.done() },
                delete: { [weak self] in await self?.delete() },
                style: .sync
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

            return UINavigationController(rootViewController: rootViewController)
        }

        @objc
        private func doneTapped() {
            done()
        }

        private func done() {
            Task {
                await viewModel.commitEditsAndExist()
            }
        }

        private func delete() async {
            logger.info("SyncedNoteEditor: delete note")
            if viewModel.hasPersistedNote, viewModel.isEditedNote {
                logger.info("SyncedNoteEditor: confirm note deletion")
                confirmNoteDelete(
                    delete: { await self.viewModel.forceDelete() },
                    cancel: { }
                )
            } else if viewModel.hasPersistedNote {
                await viewModel.forceDelete()
            } else {
                dismiss(animated: true)
            }
        }
    }
#endif
