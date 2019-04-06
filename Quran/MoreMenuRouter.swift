//
//  MoreMenuRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol MoreMenuInteractable: Interactable {
    var router: MoreMenuRouting? { get set }
    var listener: MoreMenuListener? { get set }
}

protocol MoreMenuViewControllable: ViewControllable {
}

final class MoreMenuRouter: ViewableRouter<MoreMenuInteractable, MoreMenuViewControllable>, MoreMenuRouting {

    override init(interactor: MoreMenuInteractable, viewController: MoreMenuViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
