//
//  SearchTabBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

final class SearchTabBuilder: Builder, TabBuildable {

    func build(withListener listener: TabListener) -> TabRouting {
        let viewController = SearchTabViewController()
        let interactor = TabInteractor(presenter: viewController)
        interactor.listener = listener
        return SearchTabRouter(
            interactor: interactor,
            viewController: viewController,
            searchBuilder: SearchBuilder(container: container),
            deps: TabDependenciesBuilder(container: container).build())
    }
}
