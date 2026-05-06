#if QURAN_SYNC
    //
    //  CollectionsViewController.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Localization
    import NoorUI
    import SwiftUI
    import UIKit
    import UIx

    final class CollectionsViewController: UIHostingController<CollectionsView> {
        // MARK: Lifecycle

        init(viewModel: CollectionsViewModel) {
            self.viewModel = viewModel
            super.init(rootView: CollectionsView(viewModel: viewModel))
            initialize()
        }

        @available(*, unavailable)
        @MainActor
        dynamic required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Private

        private let viewModel: CollectionsViewModel

        private func initialize() {
            title = l("bookmarks.collections")
            updateMenuButton()
        }

        private func updateMenuButton() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: NoorSystemImage.more.rawValue),
                menu: UIMenu(children: [
                    UIAction(title: l("bookmarks.collections.add"), image: UIImage(systemName: NoorSystemImage.add.rawValue)) { [weak self] _ in
                        self?.addCollection()
                    },
                    UIAction(
                        title: viewModel.editMode.isEditing ? l("button.done") : l("bookmarks.collections.edit"),
                        image: UIImage(systemName: viewModel.editMode.isEditing ? NoorSystemImage.checkmark.rawValue : NoorSystemImage.edit.rawValue)
                    ) { [weak self] _ in
                        self?.toggleEditing()
                    },
                ])
            )
        }

        private func toggleEditing() {
            withAnimation {
                viewModel.editMode = viewModel.editMode.isEditing ? .inactive : .active
            }
            updateMenuButton()
        }

        private func addCollection() {
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
            present(alert, animated: true)
        }
    }
#endif
