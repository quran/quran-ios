//
//  SettingsTab.swift
//
//
//  Created by Mohamed Afifi on 2023-06-28.
//

import AppDependencies
import Localization
import NoorUI
import QuranViewFeature
import SettingsFeature
import UIKit

struct SettingsTabBuilder: TabBuildable {
    let container: AppDependencies

    func build() -> UIViewController {
        let interactor = SettingsTabInteractor(
            quranBuilder: QuranBuilder(container: container),
            settingsBuilder: SettingsBuilder(container: container)
        )
        let viewController = SettingsTabViewController(interactor: interactor)
        return viewController
    }
}

private final class SettingsTabInteractor: TabInteractor {
    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder, settingsBuilder: SettingsBuilder) {
        self.settingsBuilder = settingsBuilder
        super.init(quranBuilder: quranBuilder)
    }

    // MARK: Internal

    override func start() {
        guard let presenter else {
            return
        }
        let rootViewController = settingsBuilder.build(navigationController: presenter)
        presenter.setViewControllers([rootViewController], animated: false)
    }

    // MARK: Private

    private let settingsBuilder: SettingsBuilder
}

private class SettingsTabViewController: TabViewController {
    override func getTabBarItem() -> UITabBarItem {
        UITabBarItem(
            title: lAndroid("menu_settings"),
            image: NoorImage.settings.uiImage,
            selectedImage: NoorImage.settingsFilled.uiImage
        )
    }
}
