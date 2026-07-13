#if QURAN_SYNC
//
//  AyahBookmarkCollectionsViewController.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import Localization
import SwiftUI
import UIKit

final class AyahBookmarkCollectionsViewController: UIHostingController<AyahBookmarkCollectionsView> {
    // MARK: Lifecycle

    init(
        viewModel: AyahBookmarkCollectionsViewModel,
        title: String = l("bookmarks.collections"),
        allowsCollectionManagement: Bool = true,
        allowsBookmarkDeletion: Bool = true
    ) {
        super.init(
            rootView: AyahBookmarkCollectionsView(
                viewModel: viewModel,
                allowsCollectionManagement: allowsCollectionManagement,
                allowsBookmarkDeletion: allowsBookmarkDeletion
            )
        )
        self.title = title
        if allowsCollectionManagement {
            menuController = AyahBookmarkCollectionsMenuController(viewController: self, viewModel: viewModel)
        }
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private var menuController: AyahBookmarkCollectionsMenuController?
}
#endif
