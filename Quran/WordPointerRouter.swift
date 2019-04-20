//
//  WordPointerRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol WordPointerInteractable: Interactable, TranslationTextTypeSelectionListener {
    var router: WordPointerRouting? { get set }
    var listener: WordPointerListener? { get set }
}

protocol WordPointerViewControllable: ViewControllable {
    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable)
}

final class WordPointerRouter: PresentingViewableRouter<WordPointerInteractable, WordPointerViewControllable>, WordPointerRouting {

    private let translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuildable

    init(interactor: WordPointerInteractable,
         viewController: WordPointerViewControllable,
         translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuildable) {
        self.translationTextTypeSelectionBuilder = translationTextTypeSelectionBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func presentTranslationTextTypeSelection() {
        let router = translationTextTypeSelectionBuilder.build(withListener: interactor)
        saveAsPresented(router)
        viewController.presentTranslationTextTypeSelectionViewController(router.viewControllable)
    }

    func dismissPresentedRouter() {
        dismiss(animated: true)
    }
}
