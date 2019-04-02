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
    // TODO: Declare methods the router invokes to manipulate the view hierarchy.
}

final class MoreMenuRouter: ViewableRouter<MoreMenuInteractable, MoreMenuViewControllable>, MoreMenuRouting {

    // TODO: Constructor inject child builder protocols to allow building children.
    override init(interactor: MoreMenuInteractable, viewController: MoreMenuViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
