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
        allowsBookmarkDeletion: Bool = true
    ) {
        super.init(
            rootView: AyahBookmarkCollectionsView(
                viewModel: viewModel,
                allowsBookmarkDeletion: allowsBookmarkDeletion
            )
        )
        self.title = title
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
