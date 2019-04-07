//
//  QuranRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QuranInteractable: Interactable, AdvancedAudioOptionsListener, TranslationTextTypeSelectionListener,
                MoreMenuListener, QariListListener, TranslationsListListener {
    var router: QuranRouting? { get set }
    var listener: QuranListener? { get set }
}

protocol QuranViewControllable: ViewControllable {
    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable)
    func presentMoreMenuViewController(_ viewController: ViewControllable)
    func presentTranslationsSelection(_ viewController: ViewControllable)
    func presentQariList(_ viewController: ViewControllable)
}

final class QuranRouter: PresentingViewableRouter<QuranInteractable, QuranViewControllable>, QuranRouting {

    struct Deps {
        let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuildable
        let translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuildable
        let moreMenuBuilder: MoreMenuBuildable
        let qariListBuilder: QariListBuildable
        let translationsSelectionBuilder: TranslationsSelectionBuildble
    }

    private let deps: Deps

    init(interactor: QuranInteractable, viewController: QuranViewControllable, deps: Deps) {
        self.deps = deps
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func dismissPresentedRouter(completion: (() -> Void)?) {
        dismiss(animated: true, completion: completion)
    }

    // MARK: - AudioOptions

    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions) {
        present { $0.advancedAudioOptionsBuilder.build(withListener: $1, options: options) }
    }

    // MARK: - Translation Text Type

    func presentTranslationTextTypeSelection() {
        present({ $0.translationTextTypeSelectionBuilder.build(withListener: $1) },
                { $0.presentTranslationTextTypeSelectionViewController($1) }) // swiftlint:disable:this opening_brace
    }

    // MARK: - More Menu

    func presentMoreMenu(withModel model: MoreMenuModel) {
        present({ $0.moreMenuBuilder.build(withListener: $1, model: model) },
                { $0.presentMoreMenuViewController($1) }) // swiftlint:disable:this opening_brace
    }

    // MARK: - Translation Selection

    func presentTranslationsSelection() {
        present({ $0.translationsSelectionBuilder.build(withListener: $1) },
                { $0.presentTranslationsSelection($1) }) // swiftlint:disable:this opening_brace
    }

    // MARK: - Qari List

    func presentQariList() {
        present({ $0.qariListBuilder.build(withListener: $1) },
                { $0.presentQariList($1) }) // swiftlint:disable:this opening_brace
    }

    private func present(_ building: (Deps, QuranInteractable) -> ViewableRouting,
                         _ present: (QuranViewControllable, ViewControllable) -> Void) {
        let router = building(deps, interactor)
        saveAsPresented(router)
        present(viewController, router.viewControllable)
    }

    private func present(_ building: (Deps, QuranInteractable) -> ViewableRouting) {
        let router = building(deps, interactor)
        present(router, animated: true)
    }
}
