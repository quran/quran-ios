//
//  AppBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol AppBuildable: Buildable {
    func build() -> AppRouting
}

final class AppBuilder: Builder, AppBuildable {

    func build() -> AppRouting {
        let viewController = AppViewController()
        let interactor = AppInteractor(presenter: viewController)
        return AppRouter(interactor: interactor, viewController: viewController, deps: AppRouter.Deps(
            surasBuilder: SurasTabBuilder(container: container),
            juzsBuilder: JuzsTabBuilder(container: container),
            bookmarksBuilder: BookmarksTabBuilder(container: container),
            searchBuilder: SearchTabBuilder(container: container),
            settingsBuilder: SettingsTabBuilder(container: container)
        ))
    }
}
