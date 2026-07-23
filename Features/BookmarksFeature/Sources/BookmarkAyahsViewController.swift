#if QURAN_SYNC
//
//  BookmarkAyahsViewController.swift
//

import Localization
import NoorUI
import SwiftUI
import UIKit

@MainActor
final class BookmarkAyahsViewController: UIHostingController<BookmarkAyahsView> {
    // MARK: Lifecycle

    init(viewModel: BookmarkAyahsViewModel) {
        super.init(rootView: BookmarkAyahsView(viewModel: viewModel))
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        configureDoneButton()
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private func configureDoneButton() {
        let doneButton = UIBarButtonItem(
            title: l("button.done"),
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )
        doneButton.tintColor = .appIdentity
        navigationItem.rightBarButtonItem = doneButton
    }
}
#endif
