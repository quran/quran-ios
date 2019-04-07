//
//  SettingsTabBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

final class SettingsTabBuilder: Builder, TabBuildable {

    func build(withListener listener: TabListener) -> TabRouting {
        let viewController = SettingsTabViewController()
        let interactor = SettingsTabInteractor(presenter: viewController)
        interactor.listener = listener
        return SettingsTabRouter(
            interactor: interactor,
            viewController: viewController,
            settingsBuilder: SettingsBuilder(container: container),
            translationsListCreator: container.createCreator(container.createTranslationsViewController),
            audioDownloadsCreator: container.createCreator(container.createAudioDownloadsViewController),
            deps: TabDependenciesBuilder(container: container).build())
    }
}
