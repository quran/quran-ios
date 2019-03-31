//
//  SurasTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

final class SurasTabRouter: TabRouter {

    private let surasBuilder: SurasBuilder

    init(interactor: TabInteractable,
         viewController: TabViewControllable,
         surasBuilder: SurasBuilder,
         deps: Deps) {
        self.surasBuilder = surasBuilder
        super.init(interactor: interactor, viewController: viewController, deps: deps)
    }

    override func createRootRouter() -> ViewableRouting {
        return surasBuilder.build(withListener: interactor)
    }
}
