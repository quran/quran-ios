//
//  AppBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import AppMigrator
import UIKit
import WhatsNewFeature

@MainActor
struct AppBuilder {
    let container: AppDependencies

    /// - Parameter launchVersion: How this launch relates to the previous one,
    ///   captured before the launch commits the current app version.
    func build(launchVersion: LaunchVersionUpdate) -> AppViewController {
        // The tabs are built before the view controller that switches between them.
        let appViewControllerReference = AppViewControllerReference()
        let interactor = AppInteractor(
            supportsCloudKit: container.supportsCloudKit,
            analytics: container.analytics,
            lastPagePersistence: container.lastPagePersistence,
            tabs: [
                HomeTabBuilder(container: container),
                NotesTabBuilder(container: container, showBookmarks: { [appViewControllerReference] in
                    appViewControllerReference.value?.showBookmarks()
                }),
                BookmarksTabBuilder(container: container),
                SearchTabBuilder(container: container),
                SettingsTabBuilder(container: container),
            ]
        )
        let appViewController = AppViewController(
            interactor: interactor,
            whatsNewController: whatsNewController(launchVersion: launchVersion),
            isAppIconAvailable: container.appIconService().isAvailable
        )
        appViewControllerReference.value = appViewController
        return appViewController
    }

    // MARK: Private

    private func whatsNewController(launchVersion: LaunchVersionUpdate) -> AppWhatsNewController {
        #if QURAN_SYNC
        AppWhatsNewController(
            analytics: container.analytics,
            launchVersion: launchVersion,
            appIconCatalog: container.appIconCatalog,
            authenticationClient: container.authenticationClient
        )
        #else
        AppWhatsNewController(
            analytics: container.analytics,
            launchVersion: launchVersion,
            appIconCatalog: container.appIconCatalog
        )
        #endif
    }
}

@MainActor
private final class AppViewControllerReference {
    weak var value: AppViewController?
}
