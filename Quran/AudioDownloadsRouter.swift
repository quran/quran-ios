//
//  AudioDownloadsRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol AudioDownloadsInteractable: Interactable {
    var router: AudioDownloadsRouting? { get set }
    var listener: AudioDownloadsListener? { get set }
}

protocol AudioDownloadsViewControllable: ViewControllable {
}

final class AudioDownloadsRouter: ViewableRouter<AudioDownloadsInteractable, AudioDownloadsViewControllable>, AudioDownloadsRouting {

    override init(interactor: AudioDownloadsInteractable, viewController: AudioDownloadsViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
