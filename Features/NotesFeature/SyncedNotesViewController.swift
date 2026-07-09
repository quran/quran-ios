#if QURAN_SYNC
//
//  SyncedNotesViewController.swift
//
//  Created by Ahmed Nabil on 2026-05-16.
//

import Combine
import Localization
import NoteEditorFeature
import QuranAnnotations
import SwiftUI
import UIx
import VLogging

final class SyncedNotesViewController: UIHostingController<SyncedNotesView>, UISearchBarDelegate, NoteEditorListener {
    // MARK: Lifecycle

    init(viewModel: SyncedNotesViewModel, noteEditorBuilder: NoteEditorBuilder) {
        self.viewModel = viewModel
        self.noteEditorBuilder = noteEditorBuilder
        super.init(rootView: SyncedNotesView(viewModel: viewModel, selectAction: { _ in }))
        rootView = SyncedNotesView(viewModel: viewModel, selectAction: { [weak self] item in self?.editNote(item.note) })
        initialize()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = l("notes.search.placeholder.text")
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true

        viewModel.$searchTerm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let bar = self?.searchController.searchBar else { return }
                if bar.text != term {
                    bar.text = term
                }
            }
            .store(in: &cancellables)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        logger.info("[Notes] search textDidChange to \(searchText)")
        viewModel.searchTerm = searchText
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        logger.info("[Notes] search cancel")
        viewModel.searchTerm = ""
    }

    func dismissNoteEditor() {
        dismiss(animated: true)
    }

    // MARK: Private

    private var editController: EditController?
    private let viewModel: SyncedNotesViewModel
    private let noteEditorBuilder: NoteEditorBuilder
    private let searchController = UISearchController(searchResultsController: nil)
    private var cancellables: Set<AnyCancellable> = []

    private var currentEditMode: EditMode? {
        if viewModel.notes.isEmpty {
            return nil
        }
        return viewModel.editMode
    }

    private func initialize() {
        title = l("tab.notes")

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
                    action: #selector(shareAllNotes)
                ),
            ]
        )
    }

    private func editNote(_ note: Note) {
        let viewController = noteEditorBuilder.build(withListener: self, note: note)
        present(viewController, animated: true)
    }

    @objc
    private func shareAllNotes() {
        Task {
            do {
                let notesText = try await viewModel.prepareNotesForSharing()
                let activityViewController = UIActivityViewController(activityItems: [notesText], applicationActivities: nil)
                let view = navigationController?.view
                let viewBound = view.map { CGRect(x: $0.bounds.midX, y: $0.bounds.midY, width: 0, height: 0) }
                activityViewController.modalPresentationStyle = .formSheet
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
                activityViewController.popoverPresentationController?.sourceView = view
                activityViewController.popoverPresentationController?.sourceRect = viewBound ?? .zero
                present(activityViewController, animated: true)
            } catch {
                showErrorAlert(error: error)
            }
        }
    }
}
#endif
