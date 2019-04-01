//
//  TranslationTextTypeSelectionRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol TranslationTextTypeSelectionInteractable: Interactable {
    var router: TranslationTextTypeSelectionRouting? { get set }
    var listener: TranslationTextTypeSelectionListener? { get set }
}

protocol TranslationTextTypeSelectionViewControllable: ViewControllable {

}

final class TranslationTextTypeSelectionRouter:
    ViewableRouter<TranslationTextTypeSelectionInteractable, TranslationTextTypeSelectionViewControllable>,
    TranslationTextTypeSelectionRouting {

    override init(interactor: TranslationTextTypeSelectionInteractable, viewController: TranslationTextTypeSelectionViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
