//
//  BookmarksViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

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

    // MARK: Private

    private var editController: EditController?
    private let viewModel: BookmarksViewModel

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
    }
}
