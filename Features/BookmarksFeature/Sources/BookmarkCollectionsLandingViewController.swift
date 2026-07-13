#if QURAN_SYNC
//
//  BookmarkCollectionsLandingViewController.swift
//

import Localization
import SwiftUI

final class BookmarkCollectionsLandingViewController: UIHostingController<BookmarkCollectionsLandingView> {
    init(viewModel: BookmarkCollectionsLandingViewModel) {
        super.init(rootView: BookmarkCollectionsLandingView(viewModel: viewModel))
        title = lAndroid("menu_bookmarks")
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
