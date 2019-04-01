//
//  AdvancedAudioOptionsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol AdvancedAudioOptionsBuildable: Buildable {
    func build(withListener listener: AdvancedAudioOptionsListener, options: AdvancedAudioOptions) -> AdvancedAudioOptionsRouting
}

final class AdvancedAudioOptionsBuilder: Builder, AdvancedAudioOptionsBuildable {

    func build(withListener listener: AdvancedAudioOptionsListener, options: AdvancedAudioOptions) -> AdvancedAudioOptionsRouting {
        let viewController = AdvancedAudioOptionsViewController(options: options)
        let interactor = AdvancedAudioOptionsInteractor(presenter: viewController)
        interactor.listener = listener
        return AdvancedAudioOptionsRouter(interactor: interactor, viewController: viewController)
    }
}
