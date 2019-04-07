//
//  TabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol TabInteractable: Interactable, SurasListener, JuzsListener, BookmarksListener, SearchListener, QuranListener {
    var router: TabRouting? { get set }
    var listener: TabListener? { get set }
}

protocol TabViewControllable: NavigationControllable {
}

class TabRouter: NavigationRouter<TabInteractable, TabViewControllable>, TabRouting {

    struct Deps {
        let quranBuilder: QuranBuildable
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
        let router = deps.quranBuilder.build(withListener: interactor, page: quranPage, lastPage: nil, highlightAyah: highlightingAyah)
        push(router, animated: true)
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        let router = deps.quranBuilder.build(withListener: interactor, page: quranPage, lastPage: lastPage, highlightAyah: nil)
        push(router, animated: true)
    }
}
