//
//  SettingsTabRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

protocol SettingsTabInteractable: TabInteractable, SettingsListener, AudioDownloadsListener, TranslationsListListener {
}

final class SettingsTabRouter: TabRouter, SettingsTabRouting {

    private let translationsListBuilder: TranslationsListBuildable
    private let audioDownloadsBuilder: AudioDownloadsBuildable
    private let settingsBuilder: SettingsBuildable
    private let settingsInteractor: SettingsTabInteractable

    init(interactor: SettingsTabInteractable,
         viewController: TabViewControllable,
         settingsBuilder: SettingsBuildable,
         translationsListBuilder: TranslationsListBuildable,
         audioDownloadsBuilder: AudioDownloadsBuildable,
         deps: Deps) {
        self.settingsInteractor = interactor
        self.settingsBuilder = settingsBuilder
        self.translationsListBuilder = translationsListBuilder
        self.audioDownloadsBuilder = audioDownloadsBuilder
        super.init(interactor: interactor, viewController: viewController, deps: deps)
    }

    override func createRootRouter() -> ViewableRouting {
        return settingsBuilder.build(withListener: settingsInteractor)
    }

    func presentTranslationsList() {
        let router = translationsListBuilder.build(withListener: settingsInteractor)
        push(router, animated: true)
    }

    func presentAudioDownloads() {
        let router = audioDownloadsBuilder.build(withListener: settingsInteractor)
        push(router, animated: true)
    }
}
