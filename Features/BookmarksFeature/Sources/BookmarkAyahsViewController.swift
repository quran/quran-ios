#if QURAN_SYNC
//
//  BookmarkAyahsViewController.swift
//

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
        navigationItem.rightBarButtonItem = NavigationBarButton.done { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}
#endif
