//
//  BookmarksViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import Combine
import Localization
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

    // MARK: Internal

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isSyncingToParent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isSyncingToParent = false
        viewModel.editMode = .inactive
    }

    // MARK: Private

    private var isSyncingToParent = true
    private var editController: EditController?
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
        addCloudSyncInfo()

        editController = EditController(
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
                action: #selector(confirmDeleteAll)
            )
            navigationItem.leftBarButtonItem?.tintColor = .systemRed
        } else {
            addCloudSyncInfo()
        }
        // EditController updates rightBarButtonItems on the same run-loop pass;
        // dispatch async so we copy after it has finished.
        DispatchQueue.main.async { [weak self] in
            self?.syncBarItemsToParent()
        }
    }

    private func syncBarItemsToParent() {
        guard let parent, isSyncingToParent else { return }
        parent.navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems
        parent.navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems
    }

    @objc
    private func confirmDeleteAll() {
        let alert = UIAlertController(
            title: l("bookmarks.delete-all"),
            message: l("bookmarks.delete-all.confirmation"),
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: l("bookmarks.delete-all"), style: .destructive) { [weak self] _ in
            Task { await self?.viewModel.deleteAll() }
        })
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel))
        present(alert, animated: true)
    }
}
