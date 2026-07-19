//
//  BookmarksTab.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import BookmarksFeature
import Localization
import QuranViewFeature
import UIKit

struct BookmarksTabBuilder: TabBuildable {
    let container: AppDependencies

    func build() -> UIViewController {
        let interactor = BookmarksTabInteractor(
            quranBuilder: QuranBuilder(container: container),
            bookmarksBuilder: BookmarksBuilder(container: container)
        )
        let viewController = BookmarksTabViewController(interactor: interactor)
        viewController.navigationBar.prefersLargeTitles = true
        return viewController
    }
}

private final class BookmarksTabInteractor: TabInteractor {
    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder, bookmarksBuilder: BookmarksBuilder) {
        self.bookmarksBuilder = bookmarksBuilder
        super.init(quranBuilder: quranBuilder)
    }

    // MARK: Internal

    override func start() {
        guard let presenter else {
            return
        }
        let rootViewController = bookmarksBuilder.build(
            withListener: self,
            navigationController: presenter
        )
        presenter.setViewControllers([rootViewController], animated: false)
    }

    // MARK: Private

    private let bookmarksBuilder: BookmarksBuilder
}

private class BookmarksTabViewController: TabViewController {
    override func getTabBarItem() -> UITabBarItem {
        #if QURAN_SYNC
        let title = l("bookmarks.collections")
        #else
        let title = lAndroid("menu_bookmarks")
        #endif
        return UITabBarItem(
            title: title,
            image: .symbol("bookmark"),
            selectedImage: .symbol("bookmark.fill")
        )
    }
}
