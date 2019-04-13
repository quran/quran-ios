//
//  QuranRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol QuranInteractable: Interactable, TranslationTextTypeSelectionListener,
                MoreMenuListener, TranslationsListListener, QuranAudioBannerListener, AyahMenuListener {
    var router: QuranRouting? { get set }
    var listener: QuranListener? { get set }
}

protocol QuranViewControllable: ViewControllable {
    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable)
    func presentMoreMenuViewController(_ viewController: ViewControllable)
    func presentTranslationsSelection(_ viewController: ViewControllable)
    func presentAudioBanner(_ viewController: ViewControllable)
    func presentAyahMenu(_ viewController: ViewControllable)
}

final class QuranRouter: PresentingViewableRouter<QuranInteractable, QuranViewControllable>, QuranRouting {

    struct Deps {
        let translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuildable
        let moreMenuBuilder: MoreMenuBuildable
        let translationsSelectionBuilder: TranslationsSelectionBuildble
        let audioBannerBuilder: QuranAudioBannerBuildable
        let ayahMenuBuilder: AyahMenuBuildable
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

    func presentTranslationTextTypeSelection() {
        present({ $0.translationTextTypeSelectionBuilder.build(withListener: $1) },
                { $0.presentTranslationTextTypeSelectionViewController($1) }) // swiftlint:disable:this opening_brace
    }

    func presentMoreMenu(withModel model: MoreMenuModel) {
        present({ $0.moreMenuBuilder.build(withListener: $1, model: model) },
                { $0.presentMoreMenuViewController($1) }) // swiftlint:disable:this opening_brace
    }

    func presentTranslationsSelection() {
        present({ $0.translationsSelectionBuilder.build(withListener: $1) },
                { $0.presentTranslationsSelection($1) }) // swiftlint:disable:this opening_brace
    }

    func presentAyahMenu(input: AyahMenuInput) {
        present({ $0.ayahMenuBuilder.build(withListener: $1, input: input) },
                { $0.presentAyahMenu($1) }) // swiftlint:disable:this opening_brace
    }

    func presentAudioBanner(playFromAyahStream: PlayFromAyahStream) {
        let router = deps.audioBannerBuilder.build(withListener: interactor, playFromAyahStream: playFromAyahStream)
        attachChild(router)
        viewController.presentAudioBanner(router.viewControllable)
    }

    // MARK: - Private

    private func present(_ building: (Deps, QuranInteractable) -> ViewableRouting,
                         _ present: (QuranViewControllable, ViewControllable) -> Void) {
        let router = building(deps, interactor)
        saveAsPresented(router)
        present(viewController, router.viewControllable)
    }
}
