//
//  SurasBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol SurasBuildable: Buildable {
    func build(withListener listener: SurasListener) -> SurasRouting
}

final class SurasBuilder: Builder, SurasBuildable {

    func build(withListener listener: SurasListener) -> SurasRouting {
        let viewController = SurasViewController(
            dataRetriever: SurasDataRetriever().asAnyGetInteractor(),
            quranControllerCreator: container.createCreator(container.createQuranController), // TODO: shouldn't be needed
            lastPagesPersistence: container.createLastPagesPersistence()
        )
        let interactor = SurasInteractor(presenter: viewController)
        interactor.listener = listener
        return SurasRouter(interactor: interactor, viewController: viewController)
    }
}
