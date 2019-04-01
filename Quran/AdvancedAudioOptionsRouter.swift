//
//  AdvancedAudioOptionsRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol AdvancedAudioOptionsInteractable: Interactable {
    var router: AdvancedAudioOptionsRouting? { get set }
    var listener: AdvancedAudioOptionsListener? { get set }
}

protocol AdvancedAudioOptionsViewControllable: ViewControllable {
    // TODO: Declare methods the router invokes to manipulate the view hierarchy.
}

final class AdvancedAudioOptionsRouter: ViewableRouter<AdvancedAudioOptionsInteractable, AdvancedAudioOptionsViewControllable>, AdvancedAudioOptionsRouting {

    // TODO: Constructor inject child builder protocols to allow building children.
    override init(interactor: AdvancedAudioOptionsInteractable, viewController: AdvancedAudioOptionsViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
