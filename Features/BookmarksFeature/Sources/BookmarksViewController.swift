//
//  BookmarksViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

#if !QURAN_SYNC
import Combine
import Localization
import NoorUI
import SwiftUI
import UIx

final class BookmarksViewController: UIHostingController<BookmarksView> {
    // MARK: Lifecycle

    init(viewModel: BookmarksViewModel) {
        self.viewModel = viewModel
        super.init(rootView: BookmarksView(viewModel: viewModel))

        initialize()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private var editController: NavigationEditModeController?
    private let viewModel: BookmarksViewModel
    private var cancellables: Set<AnyCancellable> = []

    private var currentEditMode: EditMode? {
        if viewModel.bookmarks.isEmpty {
            return nil
        }
        return viewModel.editMode
    }

    private func initialize() {
        title = lAndroid("menu_bookmarks")
        editController = NavigationEditModeController(
            navigationItem: navigationItem,
            reload: viewModel.objectWillChange.eraseToAnyPublisher(),
            editMode: Binding(
                get: { [weak self] in self?.currentEditMode },
                set: { [weak self] value in self?.viewModel.editMode = value ?? .inactive }
            )
        )

        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateDeleteAllButton() }
            .store(in: &cancellables)
    }

    private func updateDeleteAllButton() {
        if viewModel.editMode.isEditing && !viewModel.bookmarks.isEmpty {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: l("bookmarks.delete-all"),
                style: .plain,
                target: self,
                action: #selector(confirmDeleteAll(_:))
            )
            navigationItem.leftBarButtonItem?.tintColor = .systemRed
        } else {
            addCloudSyncInfo()
        }
    }

    @objc
    private func confirmDeleteAll(_ sourceBarButtonItem: UIBarButtonItem) {
        let alert = Self.makeDeleteAllConfirmation(
            sourceBarButtonItem: sourceBarButtonItem
        ) { [weak self] in
            Task { await self?.viewModel.deleteAll() }
        }
        present(alert, animated: true)
    }

    static func makeDeleteAllConfirmation(
        sourceBarButtonItem: UIBarButtonItem,
        deleteAll: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: l("bookmarks.delete-all"),
            message: l("bookmarks.delete-all.confirmation"),
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: l("bookmarks.delete-all"), style: .destructive) { _ in
            deleteAll()
        })
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel))
        alert.popoverPresentationController?.barButtonItem = sourceBarButtonItem
        return alert
    }
}
#endif
