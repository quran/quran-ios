//
//  JuzsTabBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

final class JuzsTabBuilder: Builder, TabBuildable {

    func build(withListener listener: TabListener) -> TabRouting {
        let viewController = JuzsTabViewController()
        let interactor = TabInteractor(presenter: viewController)
        interactor.listener = listener
        return JuzsTabRouter(
            interactor: interactor,
            viewController: viewController,
            juzsBuilder: JuzsBuilder(container: container),
            deps: TabDependenciesBuilder(container: container).build())
    }
}
