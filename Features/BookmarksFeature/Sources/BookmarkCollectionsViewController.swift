#if QURAN_SYNC
//
//  BookmarkCollectionsViewController.swift
//

import Localization
import SwiftUI

final class BookmarkCollectionsViewController: UIHostingController<BookmarkCollectionsView> {
    init(viewModel: BookmarkCollectionsViewModel) {
        super.init(rootView: BookmarkCollectionsView(viewModel: viewModel))
        title = l("bookmarks.collections")
        menuController = AyahBookmarkCollectionsMenuController(
            viewController: self,
            viewModel: viewModel.collectionsViewModel
        )
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var menuController: AyahBookmarkCollectionsMenuController?
}
#endif
