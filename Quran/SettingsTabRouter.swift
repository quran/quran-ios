//
//  SettingsTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

protocol SettingsTabInteractable: TabInteractable, SettingsListener, AudioDownloadsListener {
}

final class SettingsTabRouter: TabRouter, SettingsTabRouting {

    private let translationsListCreator: AnyCreator<Void, UIViewController>
    private let audioDownloadsBuilder: AudioDownloadsBuildable
    private let settingsBuilder: SettingsBuildable
    private let settingsInteractor: SettingsTabInteractable

    init(interactor: SettingsTabInteractable,
         viewController: TabViewControllable,
         settingsBuilder: SettingsBuildable,
         translationsListCreator: AnyCreator<Void, UIViewController>,
         audioDownloadsBuilder: AudioDownloadsBuildable,
         deps: Deps) {
        self.settingsInteractor = interactor
        self.settingsBuilder = settingsBuilder
        self.translationsListCreator = translationsListCreator
        self.audioDownloadsBuilder = audioDownloadsBuilder
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
        let router = audioDownloadsBuilder.build(withListener: settingsInteractor)
        push(router, animated: true)
    }
}
