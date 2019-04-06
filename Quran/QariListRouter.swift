//
//  QariListRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QariListInteractable: Interactable {
    var router: QariListRouting? { get set }
    var listener: QariListListener? { get set }
}

protocol QariListViewControllable: ViewControllable {
}

final class QariListRouter: ViewableRouter<QariListInteractable, QariListViewControllable>, QariListRouting {

    override init(interactor: QariListInteractable, viewController: QariListViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
