//
//  JuszTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

final class JuzsTabRouter: TabRouter {

    private let juzsBuilder: JuzsBuilder

    init(interactor: TabInteractable,
         viewController: TabViewControllable,
         juzsBuilder: JuzsBuilder,
         deps: Deps) {
        self.juzsBuilder = juzsBuilder
        super.init(interactor: interactor, viewController: viewController, deps: deps)
    }

    override func createRootRouter() -> ViewableRouting {
        return juzsBuilder.build(withListener: interactor)
    }
}
