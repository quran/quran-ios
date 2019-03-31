//
//  BookmarksTabBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

final class BookmarksTabBuilder: Builder, TabBuildable {

    func build(withListener listener: TabListener) -> TabRouting {
        let viewController = BookmarksTabViewController()
        let interactor = TabInteractor(presenter: viewController)
        interactor.listener = listener
        return BookmarksTabRouter(
            interactor: interactor,
            viewController: viewController,
            bookmarksBuilder: BookmarksBuilder(container: container),
            deps: TabDependenciesBuilder(container: container).build())
    }
}
