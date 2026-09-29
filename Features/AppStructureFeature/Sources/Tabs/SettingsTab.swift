//
//  SettingsTab.swift
//
//
//  Created by Mohamed Afifi on 2023-06-28.
//

import AppDependencies
import AppIconFeature
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
            settingsBuilder: SettingsBuilder(container: container),
            appIconBuilder: AppIconBuilder(container: container)
        )
        let viewController = SettingsTabViewController(interactor: interactor)
        viewController.navigationBar.prefersLargeTitles = true
        return viewController
    }
}

private final class SettingsTabInteractor: TabInteractor {
    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder, settingsBuilder: SettingsBuilder, appIconBuilder: AppIconBuilder) {
        self.settingsBuilder = settingsBuilder
        self.appIconBuilder = appIconBuilder
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

    /// Shows the App Icon list above the Settings root, as "Choose Another Icon" in What's New asks.
    func showAppIcons() {
        guard let presenter else {
            return
        }
        presenter.popToRootViewController(animated: false)
        presenter.pushViewController(appIconBuilder.build(source: .whatsNew), animated: true)
    }

    // MARK: Private

    private let settingsBuilder: SettingsBuilder
    private let appIconBuilder: AppIconBuilder
}

final class SettingsTabViewController: TabViewController {
    // MARK: Lifecycle

    fileprivate init(interactor: SettingsTabInteractor) {
        settingsInteractor = interactor
        super.init(interactor: interactor)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: Internal

    override func getTabBarItem() -> UITabBarItem {
        UITabBarItem(
            title: lAndroid("menu_settings"),
            image: NoorImage.settings.uiImage,
            selectedImage: NoorImage.settingsFilled.uiImage
        )
    }

    func showAppIcons() {
        settingsInteractor.showAppIcons()
    }

    // MARK: Private

    private let settingsInteractor: SettingsTabInteractor
}
