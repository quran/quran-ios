#if QURAN_SYNC
//
//  BookmarkCollectionsViewController.swift
//

import Combine
import Localization
import NoorUI
import SwiftUI
import UIx

final class BookmarkCollectionsViewController: UIHostingController<BookmarkCollectionsView> {
    init(viewModel: BookmarkCollectionsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: BookmarkCollectionsView(viewModel: viewModel))
        title = l("bookmarks.collections")
        configureEditButton()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var currentEditMode: EditMode? {
        viewModel.hasDeletableCollections ? viewModel.editMode : nil
    }

    private let viewModel: BookmarkCollectionsViewModel
    private var editController: EditController?

    private func configureEditButton() {
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.presentAddCollection()
            }
        )
        addButton.tintColor = .appIdentity

        editController = EditController(
            navigationItem: navigationItem,
            reload: viewModel.objectWillChange.eraseToAnyPublisher(),
            editMode: Binding(
                get: { [weak self] in self?.currentEditMode },
                set: { [weak self] value in self?.viewModel.editMode = value ?? .inactive }
            ),
            customItems: [addButton]
        )
    }
}
#endif
