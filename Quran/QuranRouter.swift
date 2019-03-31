//
//  QuranRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol QuranInteractable: Interactable {
    var router: QuranRouting? { get set }
    var listener: QuranListener? { get set }
}

protocol QuranViewControllable: ViewControllable {
    // TODO: Declare methods the router invokes to manipulate the view hierarchy.
}

final class QuranRouter: ViewableRouter<QuranInteractable, QuranViewControllable>, QuranRouting {

    // TODO: Constructor inject child builder protocols to allow building children.
    override init(interactor: QuranInteractable, viewController: QuranViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
