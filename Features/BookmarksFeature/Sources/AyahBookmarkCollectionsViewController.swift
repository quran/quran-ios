#if QURAN_SYNC
//
//  AyahBookmarkCollectionsViewController.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import Combine
import Localization
import NoorUI
import SwiftUI
import UIKit

final class AyahBookmarkCollectionsViewController: UIHostingController<AyahBookmarkCollectionsView> {
    // MARK: Lifecycle

    init(
        viewModel: AyahBookmarkCollectionsViewModel,
        title: String = l("bookmarks.collections")
    ) {
        super.init(rootView: AyahBookmarkCollectionsView(viewModel: viewModel))
        self.title = title
        menuController = AyahBookmarkCollectionMenuController(
            viewController: self,
            viewModel: viewModel
        )
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var menuController: AyahBookmarkCollectionMenuController?
}

@MainActor
private final class AyahBookmarkCollectionMenuController {
    init(viewController: UIViewController, viewModel: AyahBookmarkCollectionsViewModel) {
        self.viewController = viewController
        self.viewModel = viewModel

        updateNavigationItem(editMode: viewModel.editMode, collection: viewModel.collection)
        Publishers.CombineLatest(viewModel.$editMode, viewModel.$collection)
            .sink { [weak self] editMode, collection in
                self?.updateNavigationItem(editMode: editMode, collection: collection)
            }
            .store(in: &cancellables)
    }

    private weak var viewController: UIViewController?
    private let viewModel: AyahBookmarkCollectionsViewModel
    private var cancellables: Set<AnyCancellable> = []

    private func updateNavigationItem(editMode: EditMode, collection: AyahBookmarkCollection?) {
        guard let viewController, let collection else {
            return
        }

        viewController.title = collection.kind.highlightColor?.localizedName ?? collection.collection.name
        if editMode.isEditing {
            let doneButton = UIBarButtonItem(
                title: l("button.done"),
                primaryAction: UIAction { [weak self] _ in
                    self?.viewModel.editMode = .inactive
                }
            )
            doneButton.tintColor = .appIdentity
            viewController.navigationItem.rightBarButtonItem = doneButton
        } else {
            let actions = actions(for: collection)
            let button = if let singleAction = actions.first, actions.count == 1 {
                UIBarButtonItem(
                    title: singleAction.title,
                    primaryAction: singleAction
                )
            } else {
                UIBarButtonItem(
                    image: UIImage(systemName: "ellipsis.circle"),
                    menu: UIMenu(children: actions)
                )
            }
            button.tintColor = .appIdentity
            viewController.navigationItem.rightBarButtonItem = button
        }
    }

    private func actions(for collection: AyahBookmarkCollection) -> [UIAction] {
        var actions = [
            UIAction(
                title: l("bookmarks.collections.edit.action"),
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                self?.viewModel.editMode = .active
            },
        ]

        if collection.kind.canRename {
            actions.append(
                UIAction(
                    title: l("bookmarks.collections.rename"),
                    image: UIImage(systemName: "pencil.line")
                ) { [weak self] _ in
                    self?.viewModel.presentRenameCollection()
                }
            )
        }

        if collection.kind.canDelete {
            actions.append(
                UIAction(
                    title: l("button.delete"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [weak self] _ in
                    guard let self else {
                        return
                    }
                    Task { await self.viewModel.deleteCollection() }
                }
            )
        }

        return actions
    }
}
#endif
