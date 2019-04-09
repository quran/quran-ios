//
//  QuranAudioBannerRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QuranAudioBannerInteractable: Interactable, QariListListener, AdvancedAudioOptionsListener {
    var router: QuranAudioBannerRouting? { get set }
    var listener: QuranAudioBannerListener? { get set }
}

protocol QuranAudioBannerViewControllable: ViewControllable {
    func presentQariList(_ viewController: ViewControllable)
}

final class QuranAudioBannerRouter:
    PresentingViewableRouter<QuranAudioBannerInteractable, QuranAudioBannerViewControllable>,
    QuranAudioBannerRouting {

    struct Deps {
        let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuildable
        let qariListBuilder: QariListBuildable
    }

    private let deps: Deps

    init(interactor: QuranAudioBannerInteractable, viewController: QuranAudioBannerViewControllable, deps: Deps) {
        self.deps = deps
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func presentQariList() {
        present({ $0.qariListBuilder.build(withListener: $1) },
                { $0.presentQariList($1) }) // swiftlint:disable:this opening_brace
    }

    func presentAdvancedAudioOptions(with options: AdvancedAudioOptions) {
        present { $0.advancedAudioOptionsBuilder.build(withListener: $1, options: options) }
    }

    func dismissPresentedRouter() {
        dismiss(animated: true)
    }

    private func present(_ building: (Deps, QuranAudioBannerInteractable) -> ViewableRouting,
                         _ present: (QuranAudioBannerViewControllable, ViewControllable) -> Void) {
        let router = building(deps, interactor)
        saveAsPresented(router)
        present(viewController, router.viewControllable)
    }

    private func present(_ building: (Deps, QuranAudioBannerInteractable) -> ViewableRouting) {
        let router = building(deps, interactor)
        present(router, animated: true)
    }
}
