#if QURAN_SYNC
//
//  AyahBookmarkCollectionsMenuController.swift
//

import Combine
import Localization
import NoorUI
import UIKit

@MainActor
final class AyahBookmarkCollectionsMenuController {
    init(viewController: UIViewController, viewModel: AyahBookmarkCollectionsViewModel) {
        self.viewController = viewController
        self.viewModel = viewModel

        updateMenuButton()
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateMenuButton() }
            .store(in: &cancellables)
    }

    private weak var viewController: UIViewController?
    private let viewModel: AyahBookmarkCollectionsViewModel
    private var cancellables: Set<AnyCancellable> = []

    private func updateMenuButton() {
        guard let viewController else {
            return
        }

        if viewModel.editMode.isEditing {
            viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: l("button.done"),
                primaryAction: UIAction { [weak self] _ in
                    self?.viewModel.editMode = .inactive
                }
            )
        } else {
            let addAction = UIAction(
                title: l("bookmarks.collections.add"),
                image: UIImage(systemName: "plus")
            ) { [weak self] _ in
                self?.addCollection()
            }
            let editAction = UIAction(
                title: l("bookmarks.collections.edit"),
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                self?.viewModel.editMode = .active
            }
            let actions = viewModel.collections.isEmpty ? [addAction] : [addAction, editAction]
            viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: NoorSystemImage.more.rawValue),
                menu: UIMenu(children: actions)
            )
        }
    }

    private func addCollection() {
        guard let viewController else {
            return
        }

        let alert = UIAlertController(
            title: l("bookmarks.collections.add"),
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = l("bookmarks.collections.new.placeholder")
        }
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: l("bookmarks.collections.add"), style: .default) { [weak self, weak alert] _ in
            guard let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty
            else {
                return
            }
            Task {
                await self?.viewModel.createCollection(name: name)
            }
        })
        viewController.present(alert, animated: true)
    }
}
#endif
