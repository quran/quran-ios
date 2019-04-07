//
//  SettingsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol SettingsBuildable: Buildable {
    func build(withListener listener: SettingsListener) -> SettingsRouting
}

final class SettingsBuilder: Builder, SettingsBuildable {

    func build(withListener listener: SettingsListener) -> SettingsRouting {
        let viewController = SettingsViewController()
        let interactor = SettingsInteractor(presenter: viewController, application: .shared, deps: SettingsInteractor.Deps(
            persistence: container.createSimplePersistence()
        ))
        interactor.listener = listener
        return SettingsRouter(interactor: interactor, viewController: viewController)
    }
}
