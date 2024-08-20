//
//  NotesViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import Localization
import SwiftUI
import UIx

final class NotesViewController: UIHostingController<NotesView> {
    // MARK: Lifecycle

    init(viewModel: NotesViewModel) {
        self.viewModel = viewModel
        super.init(rootView: NotesView(viewModel: viewModel))

        initialize()
    }
    
    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private var editController: EditController?
    private let viewModel: NotesViewModel

    private var currentEditMode: EditMode? {
        if viewModel.notes.isEmpty {
            return nil
        }
        return viewModel.editMode
    }

    private func initialize() {
        title = l("tab.notes")
        addCloudSyncInfo()

        editController = EditController(
            navigationItem: navigationItem,
            reload: viewModel.objectWillChange.eraseToAnyPublisher(),
            editMode: Binding(
                get: { [weak self] in self?.currentEditMode },
                set: { [weak self] value in self?.viewModel.editMode = value ?? .inactive }
            ),
            customItems: [
                UIBarButtonItem(
                    image: UIImage(systemName: "square.and.arrow.up"),
                    style: .plain,
                    target: self,
                    action: #selector(shareAllNotes))])
    }    

    @objc private func shareAllNotes() {
        Task {
            let notesText = await viewModel.prepareNotesForSharing()
            let activityViewController = UIActivityViewController(activityItems: [notesText], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            
            present(activityViewController, animated: true, completion: nil)
        }
    }
}
