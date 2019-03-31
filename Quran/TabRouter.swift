//
//  TabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol TabInteractable: Interactable, SurasListener, JuzsListener, BookmarksListener, SearchListener, SettingsListener {
    var router: TabRouting? { get set }
    var listener: TabListener? { get set }
}

protocol TabViewControllable: NavigationControllable {
}

class TabRouter: NavigationRouter<TabInteractable, TabViewControllable>, TabRouting {

    struct Deps {
        let quranControllerCreator: AnyCreator<(Int, LastPage?, AyahNumber?), QuranViewController> // TODO: should be a router
    }

    private let deps: Deps

    init(interactor: TabInteractable, viewController: TabViewControllable, deps: Deps) {
        self.deps = deps
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    override func didLoad() {
        super.didLoad()
        let router = createRootRouter()
        setRouters([router], animated: false)
    }

    func createRootRouter() -> ViewableRouting {
        expectedToBeSubclassed()
    }

    func navigateTo(quranPage: Int, highlightingAyah: AyahNumber) {
        let controller = deps.quranControllerCreator.create((quranPage, nil, highlightingAyah))
        controller.hidesBottomBarWhenPushed = true
        viewController.uinavigationController.pushViewController(controller, animated: true)
    }
}
