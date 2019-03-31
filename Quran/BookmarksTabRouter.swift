//
//  BookmarksTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

final class BookmarksTabRouter: TabRouter {

    private let bookmarksBuilder: BookmarksBuilder

    init(interactor: TabInteractable,
         viewController: TabViewControllable,
         bookmarksBuilder: BookmarksBuilder,
         deps: Deps) {
        self.bookmarksBuilder = bookmarksBuilder
        super.init(interactor: interactor, viewController: viewController, deps: deps)
    }

    override func createRootRouter() -> ViewableRouting {
        return bookmarksBuilder.build(withListener: interactor)
    }
}
