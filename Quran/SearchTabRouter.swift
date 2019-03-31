//
//  SearchTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

final class SearchTabRouter: TabRouter {

    private let searchBuilder: SearchBuilder

    init(interactor: TabInteractable,
         viewController: TabViewControllable,
         searchBuilder: SearchBuilder,
         deps: Deps) {
        self.searchBuilder = searchBuilder
        super.init(interactor: interactor, viewController: viewController, deps: deps)
    }

    override func createRootRouter() -> ViewableRouting {
        return searchBuilder.build(withListener: interactor)
    }
}
