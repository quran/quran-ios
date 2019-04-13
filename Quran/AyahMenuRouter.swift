//
//  AyahMenuRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol AyahMenuInteractable: Interactable {
    var router: AyahMenuRouting? { get set }
    var listener: AyahMenuListener? { get set }
}

protocol AyahMenuViewControllable: ViewControllable {
}

final class AyahMenuRouter: ViewableRouter<AyahMenuInteractable, AyahMenuViewControllable>, AyahMenuRouting {

    override init(interactor: AyahMenuInteractable, viewController: AyahMenuViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
