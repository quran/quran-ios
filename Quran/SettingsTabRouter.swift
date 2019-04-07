//
//  SettingsTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

protocol SettingsTabInteractable: TabInteractable, SettingsListener {
}

final class SettingsTabRouter: TabRouter, SettingsTabRouting {

    private let translationsListCreator: AnyCreator<Void, UIViewController>
    private let audioDownloadsCreator: AnyCreator<Void, UIViewController>
    private let settingsBuilder: SettingsBuilder
    private let settingsInteractor: SettingsTabInteractable

    init(interactor: SettingsTabInteractable,
         viewController: TabViewControllable,
         settingsBuilder: SettingsBuilder,
         translationsListCreator: AnyCreator<Void, UIViewController>,
         audioDownloadsCreator: AnyCreator<Void, UIViewController>,
         deps: Deps) {
        self.settingsInteractor = interactor
        self.settingsBuilder = settingsBuilder
        self.translationsListCreator = translationsListCreator
        self.audioDownloadsCreator = audioDownloadsCreator
        super.init(interactor: interactor, viewController: viewController, deps: deps)
    }

    override func createRootRouter() -> ViewableRouting {
        return settingsBuilder.build(withListener: settingsInteractor)
    }

    func presentTranslationsList() {
        let translationsListController = translationsListCreator.create(())
        self.viewController.uinavigationController.pushViewController(translationsListController, animated: true)
    }

    func presentAudioDownloads() {
        let audioDownloadsController = audioDownloadsCreator.create(())
        self.viewController.uinavigationController.pushViewController(audioDownloadsController, animated: true)
    }

}
