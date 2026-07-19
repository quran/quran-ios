//
//  AppBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import UIKit

@MainActor
struct AppBuilder {
    let container: AppDependencies

    func build() -> UIViewController {
        let interactor = AppInteractor(
            supportsCloudKit: container.supportsCloudKit,
            analytics: container.analytics,
            lastPagePersistence: container.lastPagePersistence,
            tabs: [
                HomeTabBuilder(container: container),
                NotesTabBuilder(container: container),
                BookmarksTabBuilder(container: container),
                SearchTabBuilder(container: container),
                SettingsTabBuilder(container: container),
            ]
        )
        let viewController = AppViewController(
            analytics: container.analytics,
            interactor: interactor
        )
        return viewController
    }
}
