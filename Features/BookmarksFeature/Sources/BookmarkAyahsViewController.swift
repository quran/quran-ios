#if QURAN_SYNC
//
//  BookmarkAyahsViewController.swift
//

import Localization
import NoorUI
import QuranKit
import SwiftUI
import UIKit

@MainActor
final class BookmarkAyahsViewController: UIHostingController<BookmarkAyahsView> {
    // MARK: Lifecycle

    init(viewModel: BookmarkAyahsViewModel) {
        super.init(rootView: BookmarkAyahsView(viewModel: viewModel))
        configureTitle(for: viewModel.verses)
        navigationItem.largeTitleDisplayMode = .never
        configureDoneButton()
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static func title(for verses: [AyahNumber]) -> MultipartText? {
        guard let start = verses.first, let end = verses.last else {
            return nil
        }
        return "\(ayahRange: start ... end)"
    }

    // MARK: Private

    private func configureTitle(for verses: [AyahNumber]) {
        guard let title = Self.title(for: verses) else {
            return
        }

        let label = UILabel()
        label.attributedText = title.attributedString(ofSize: .body)
        label.accessibilityLabel = title.accessibilityText
        navigationItem.titleView = label
    }

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
