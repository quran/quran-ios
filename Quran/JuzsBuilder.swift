//
//  JuzsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol JuzsBuildable: Buildable {
    func build(withListener listener: JuzsListener) -> JuzsRouting
}

final class JuzsBuilder: Builder, JuzsBuildable {

    func build(withListener listener: JuzsListener) -> JuzsRouting {
        let viewController = JuzsViewController(
            dataRetriever: QuartersDataRetriever().asAnyGetInteractor(),
            lastPagesPersistence: container.createLastPagesPersistence())
        let interactor = JuzsInteractor(presenter: viewController)
        interactor.listener = listener
        return JuzsRouter(interactor: interactor, viewController: viewController)
    }
}
