#if QURAN_SYNC
//
//  BookmarkCollectionsViewController.swift
//

import Combine
import Localization
import NoorUI
import SwiftUI

final class BookmarkCollectionsViewController: UIHostingController<BookmarkCollectionsView> {
    init(viewModel: BookmarkCollectionsViewModel) {
        super.init(rootView: BookmarkCollectionsView(viewModel: viewModel))
        title = l("bookmarks.collections")
        menuController = BookmarkCollectionsMenuController(
            viewController: self,
            viewModel: viewModel
        )
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var menuController: BookmarkCollectionsMenuController?
}

@MainActor
private final class BookmarkCollectionsMenuController {
    init(viewController: UIViewController, viewModel: BookmarkCollectionsViewModel) {
        self.viewController = viewController
        self.viewModel = viewModel

        updateMenuButton(
            editMode: viewModel.editMode,
            hasDeletableCollections: viewModel.hasDeletableCollections
        )
        Publishers.CombineLatest(viewModel.$editMode, viewModel.$collections)
            .sink { [weak self] editMode, collections in
                self?.updateMenuButton(
                    editMode: editMode,
                    hasDeletableCollections: !BookmarkCollectionsViewModel
                        .deletableCollections(from: collections)
                        .isEmpty
                )
            }
            .store(in: &cancellables)
    }

    private weak var viewController: UIViewController?
    private let viewModel: BookmarkCollectionsViewModel
    private var cancellables: Set<AnyCancellable> = []

    private func updateMenuButton(editMode: EditMode, hasDeletableCollections: Bool) {
        guard let viewController else {
            return
        }

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.presentAddCollection()
            }
        )
        addButton.tintColor = .appIdentity
        viewController.navigationItem.rightBarButtonItem = addButton

        if editMode.isEditing {
            let doneButton = UIBarButtonItem(
                title: l("button.done"),
                primaryAction: UIAction { [weak self] _ in
                    self?.viewModel.editMode = .inactive
                }
            )
            doneButton.tintColor = .appIdentity
            viewController.navigationItem.leftBarButtonItem = doneButton
        } else if hasDeletableCollections {
            let editButton = UIBarButtonItem(
                title: l("bookmarks.collections.edit.action"),
                primaryAction: UIAction { [weak self] _ in
                    self?.viewModel.editMode = .active
                }
            )
            editButton.tintColor = .appIdentity
            viewController.navigationItem.leftBarButtonItem = editButton
        } else {
            viewController.navigationItem.leftBarButtonItem = nil
        }
    }
}
#endif
