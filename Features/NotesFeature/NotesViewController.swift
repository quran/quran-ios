//
//  NotesViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import Combine
import Localization
import SwiftUI
import UIx
import VLogging

final class NotesViewController: UIHostingController<NotesView>, UISearchBarDelegate {
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

    // MARK: - Search delegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        logger.info("[Notes] search textDidChange to \(searchText)")
        viewModel.searchTerm = searchText
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        logger.info("[Notes] search cancel")
        viewModel.searchTerm = ""
    }

    // MARK: Private

    private var editController: EditController?
    private let viewModel: NotesViewModel
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
                    action: #selector(shareAllNotes)
                ),
            ]
        )
    }

    @objc
    private func shareAllNotes() {
        Task {
            do {
                let notesText = try await viewModel.prepareNotesForSharing()

                let activityViewController = UIActivityViewController(activityItems: [notesText], applicationActivities: nil)

                // iPad support
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
