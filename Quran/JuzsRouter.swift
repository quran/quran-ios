//
//  JuzsRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol JuzsInteractable: Interactable {
    var router: JuzsRouting? { get set }
    var listener: JuzsListener? { get set }
}

protocol JuzsViewControllable: ViewControllable {
}

final class JuzsRouter: ViewableRouter<JuzsInteractable, JuzsViewControllable>, JuzsRouting {

    override init(interactor: JuzsInteractable, viewController: JuzsViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
