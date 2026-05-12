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
            self.viewModel = viewModel
            super.init(rootView: AyahBookmarkCollectionsView(viewModel: viewModel))
            self.title = title
            initialize()
        }

        @available(*, unavailable)
        @MainActor
        dynamic required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Private

        private let viewModel: AyahBookmarkCollectionsViewModel
        private var cancellables: Set<AnyCancellable> = []

        private func initialize() {
            updateMenuButton()

            viewModel.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.updateMenuButton() }
                .store(in: &cancellables)
        }

        private func updateMenuButton() {
            if viewModel.editMode.isEditing {
                navigationItem.rightBarButtonItem = UIBarButtonItem(
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
                navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: NoorSystemImage.more.rawValue),
                    menu: viewModel.collections.isEmpty ? UIMenu(children: [addAction]) : UIMenu(children: [addAction, editAction])
                )
            }
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
