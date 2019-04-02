//
//  MoreMenuBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol MoreMenuBuildable: Buildable {
    func build(withListener listener: MoreMenuListener, model: MoreMenuModel) -> MoreMenuRouting
}

final class MoreMenuBuilder: Builder, MoreMenuBuildable {

    func build(withListener listener: MoreMenuListener, model: MoreMenuModel) -> MoreMenuRouting {
        let viewController = MoreMenuViewController(model: model)
        let interactor = MoreMenuInteractor(presenter: viewController)
        interactor.listener = listener
        return MoreMenuRouter(interactor: interactor, viewController: viewController)
    }
}
