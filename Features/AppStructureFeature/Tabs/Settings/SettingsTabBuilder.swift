//
//  SettingsTab.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import AudioDownloadsFeature
import QuranAudioKit
import QuranViewFeature
import SettingsFeature
import SettingsService
import TranslationsFeature
import UIKit

@MainActor
struct SettingsTabBuilder: TabBuildable {
    let container: AppDependencies

    func build() -> UIViewController {
        let interactor = SettingsTabInteractor(
            quranBuilder: QuranBuilder(container: container),
            deps: SettingsTabInteractor.Deps(
                analytics: container.analytics,
                themeService: ThemeSettingsService(),
                reviewService: ReviewService(analytics: container.analytics),
                audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
                translationsListBuilder: TranslationsListBuilder(container: container),
                settingsBuilder: SettingsBuilder()
            )
        )
        let viewController = SettingsTabViewController(interactor: interactor)
        return viewController
    }
}
