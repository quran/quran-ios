//
//  SettingsTabInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol SettingsTabRouting: TabRouting {
    func presentTranslationsList()
    func presentAudioDownloads()
}

final class SettingsTabInteractor: TabInteractor, SettingsTabInteractable {
    var settingsRouter: SettingsTabRouting? {
        return router as? SettingsTabRouting
    }

    func presentTranslationsList() {
        settingsRouter?.presentTranslationsList()
    }

    func presentAudioDownloads() {
        settingsRouter?.presentAudioDownloads()
    }
}
