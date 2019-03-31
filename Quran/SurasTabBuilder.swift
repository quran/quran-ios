//
//  SurasTabBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

final class SurasTabBuilder: Builder, TabBuildable {

    func build(withListener listener: TabListener) -> TabRouting {
        let viewController = SurasTabViewController()
        let interactor = TabInteractor(presenter: viewController)
        interactor.listener = listener
        return SurasTabRouter(
            interactor: interactor,
            viewController: viewController,
            surasBuilder: SurasBuilder(container: container),
            deps: TabDependenciesBuilder(container: container).build())
    }
}
