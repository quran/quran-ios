//
//  SurasRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol SurasInteractable: Interactable {
    var router: SurasRouting? { get set }
    var listener: SurasListener? { get set }
}

protocol SurasViewControllable: ViewControllable {
}

final class SurasRouter: ViewableRouter<SurasInteractable, SurasViewControllable>, SurasRouting {

    override init(interactor: SurasInteractable, viewController: SurasViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
