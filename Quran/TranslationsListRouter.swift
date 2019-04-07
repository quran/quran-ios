//
//  TranslationsListRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol TranslationsListInteractable: Interactable {
    var router: TranslationsListRouting? { get set }
    var listener: TranslationsListListener? { get set }
}

protocol TranslationsListViewControllable: ViewControllable {
}

final class TranslationsListRouter: ViewableRouter<TranslationsListInteractable, TranslationsListViewControllable>, TranslationsListRouting {

    override init(interactor: TranslationsListInteractable, viewController: TranslationsListViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
