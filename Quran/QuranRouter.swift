//
//  QuranRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QuranInteractable: Interactable, AdvancedAudioOptionsListener, TranslationTextTypeSelectionListener, MoreMenuListener {
    var router: QuranRouting? { get set }
    var listener: QuranListener? { get set }
}

protocol QuranViewControllable: ViewControllable {
    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable)
    func presentMoreMenuViewController(_ viewController: ViewControllable)
    func presentTranslationsSelection()
}

final class QuranRouter: ViewableRouter<QuranInteractable, QuranViewControllable>, QuranRouting {

    struct Deps {
        let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuildable
        let translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuildable
        let moreMenuBuilder: MoreMenuBuildable
    }

    private let deps: Deps

    init(interactor: QuranInteractable, viewController: QuranViewControllable, deps: Deps) {
        self.deps = deps
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    // MARK: - AudioOptions

    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions) {
        let router = deps.advancedAudioOptionsBuilder.build(withListener: interactor, options: options)
        present(router, animated: true)
    }

    func dismissAdvancedAudioOptions() {
        dismiss(animated: true)
    }

    // MARK: - Translation Text Type

    func presentTranslationTextTypeSelection() {
        let router = deps.translationTextTypeSelectionBuilder.build(withListener: interactor)
        viewController.presentTranslationTextTypeSelectionViewController(router.viewControllable)
        attachChild(router)
    }

    func dismissTranslationTextTypeSelection() {
        dismiss(animated: true)
    }

    // MARK: - More Menu

    func presentMoreMenu(withModel model: MoreMenuModel) {
        let router = deps.moreMenuBuilder.build(withListener: interactor, model: model)
        viewController.presentMoreMenuViewController(router.viewControllable)
        attachChild(router)
    }

    func dismissMoreMenu() {
        dismiss(animated: true)
    }

    // MARK: - Translation Selection

    func presentTranslationsSelection() {
        viewController.presentTranslationsSelection()
    }
}
