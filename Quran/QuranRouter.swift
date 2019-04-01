//
//  QuranRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QuranInteractable: Interactable, AdvancedAudioOptionsListener {
    var router: QuranRouting? { get set }
    var listener: QuranListener? { get set }
}

protocol QuranViewControllable: ViewControllable {
}

final class QuranRouter: ViewableRouter<QuranInteractable, QuranViewControllable>, QuranRouting {

    struct Deps {
        let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuildable
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
}
