#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionPickerViewController.swift
    //
    //  Created by Ahmed Nabil on 2026-05-09.
    //

    import Localization
    import NoorUI
    import SwiftUI
    import UIKit

    final class AyahBookmarkCollectionPickerViewController: UIHostingController<AyahBookmarkCollectionPickerView> {
        // MARK: Lifecycle

        init(viewModel: AyahBookmarkCollectionPickerViewModel) {
            self.viewModel = viewModel
            super.init(rootView: AyahBookmarkCollectionPickerView(viewModel: viewModel))
            title = l("ayah-bookmark.save-verse")
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                primaryAction: UIAction { [weak self] _ in
                    self?.addCollection()
                }
            )
            navigationItem.leftBarButtonItem?.accessibilityLabel = l("bookmarks.collections.add")
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: l("button.done"),
                primaryAction: UIAction { [weak self] _ in
                    Task {
                        await self?.viewModel.saveSelectedCollections()
                    }
                }
            )
        }

        @available(*, unavailable)
        @MainActor
        dynamic required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Private

        private let viewModel: AyahBookmarkCollectionPickerViewModel

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
