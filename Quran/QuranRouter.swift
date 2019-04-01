//
//  QuranRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QuranInteractable: Interactable, AdvancedAudioOptionsListener, TranslationTextTypeSelectionListener {
    var router: QuranRouting? { get set }
    var listener: QuranListener? { get set }
}

protocol QuranViewControllable: ViewControllable {
    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable)
}

final class QuranRouter: ViewableRouter<QuranInteractable, QuranViewControllable>, QuranRouting {

    struct Deps {
        let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuildable
        let translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuildable
    }

    private let deps: Deps

    init(interactor: QuranInteractable, viewController: QuranViewControllable, deps: Deps) {
        self.deps = deps
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions) {
        let router = deps.advancedAudioOptionsBuilder.build(withListener: interactor, options: options)
        present(router, animated: true)
    }

    func dismissAdvancedAudioOptions() {
        dismiss(animated: true)
    }

    func presentTranslationTextTypeSelection() {
        let router = deps.translationTextTypeSelectionBuilder.build(withListener: interactor)
        viewController.presentTranslationTextTypeSelectionViewController(router.viewControllable)
        attachChild(router)
    }

    func dismissTranslationTextTypeSelection() {
        dismiss(animated: true)
    }
}
