//
//  QuranRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QuranInteractable: Interactable, AdvancedAudioOptionsListener, TranslationTextTypeSelectionListener, MoreMenuListener, QariListListener {
    var router: QuranRouting? { get set }
    var listener: QuranListener? { get set }
}

protocol QuranViewControllable: ViewControllable {
    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable)
    func presentMoreMenuViewController(_ viewController: ViewControllable)
    func presentTranslationsSelection()
    func presentQariList(_ viewController: ViewControllable)
}

final class QuranRouter: PresentingViewableRouter<QuranInteractable, QuranViewControllable>, QuranRouting {

    struct Deps {
        let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuildable
        let translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuildable
        let moreMenuBuilder: MoreMenuBuildable
        let qariListBuilder: QariListBuildable
    }

    private let deps: Deps

    init(interactor: QuranInteractable, viewController: QuranViewControllable, deps: Deps) {
        self.deps = deps
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func dismissPresentedRouter() {
        dismiss(animated: true)
    }

    // MARK: - AudioOptions

    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions) {
        let router = deps.advancedAudioOptionsBuilder.build(withListener: interactor, options: options)
        present(router, animated: true)
    }

    // MARK: - Translation Text Type

    func presentTranslationTextTypeSelection() {
        let router = deps.translationTextTypeSelectionBuilder.build(withListener: interactor)
        saveAsPresented(router)
        viewController.presentTranslationTextTypeSelectionViewController(router.viewControllable)
    }

    // MARK: - More Menu

    func presentMoreMenu(withModel model: MoreMenuModel) {
        let router = deps.moreMenuBuilder.build(withListener: interactor, model: model)
        saveAsPresented(router)
        viewController.presentMoreMenuViewController(router.viewControllable)
    }

    // MARK: - Translation Selection

    func presentTranslationsSelection() {
        viewController.presentTranslationsSelection()
    }

    // MARK: - Qari List

    func presentQariList() {
        let router = deps.qariListBuilder.build(withListener: interactor)
        saveAsPresented(router)
        viewController.presentQariList(router.viewControllable)
    }
}
