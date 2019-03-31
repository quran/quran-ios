//
//  AppRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol AppInteractable: Interactable, TabListener {
    var router: AppRouting? { get set }
}

protocol AppViewControllable: ViewControllable {
    func setViewControllers(_ viewControllers: [ViewControllable], animated: Bool)
}

final class AppRouter: ViewableRouter<AppInteractable, AppViewControllable>, AppRouting {

    struct Deps {
        let surasBuilder: TabBuildable
        let juzsBuilder: TabBuildable
        let bookmarksBuilder: TabBuildable
        let searchBuilder: TabBuildable
        let settingsBuilder: TabBuildable
    }

    private let deps: Deps

    init(interactor: AppInteractable, viewController: AppViewControllable, deps: Deps) {
        self.deps = deps
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    override func didLoad() {
        super.didLoad()

        let tabsBuilders = [deps.surasBuilder,
                            deps.juzsBuilder,
                            deps.bookmarksBuilder,
                            deps.searchBuilder,
                            deps.settingsBuilder]
        let tabsRouters = tabsBuilders.map { $0.build(withListener: interactor) }
        tabsRouters.forEach { attachChild($0) }
        let viewControllers = tabsRouters.map { $0.viewControllable }
        viewController.setViewControllers(viewControllers, animated: false)
    }
}
