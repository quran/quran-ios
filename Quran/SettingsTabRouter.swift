//
//  SettingsTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

final class SettingsTabRouter: TabRouter {

    private let settingsBuilder: SettingsBuilder

    init(interactor: TabInteractable,
         viewController: TabViewControllable,
         settingsBuilder: SettingsBuilder,
         deps: Deps) {
        self.settingsBuilder = settingsBuilder
        super.init(interactor: interactor, viewController: viewController, deps: deps)
    }

    override func createRootRouter() -> ViewableRouting {
        return settingsBuilder.build(withListener: interactor)
    }
}
