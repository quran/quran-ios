//
//  AppBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import AppMigrator
#if QURAN_SYNC
import Analytics
import AuthenticationClient
import FeaturesSupport
import NoorUI
import VLogging
#endif
import SystemDependencies
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
            bundle: DefaultSystemBundle(),
            appDistribution: DefaultAppDistribution(),
            authenticationClient: container.authenticationClient,
            signIn: { [container] viewController in
                Task {
                    await Self.signInToQuranCom(
                        on: viewController,
                        authenticationClient: container.authenticationClient,
                        analytics: container.analytics
                    )
                }
            }
        )
        #else
        AppWhatsNewController(
            analytics: container.analytics,
            launchVersion: launchVersion,
            appIconCatalog: container.appIconCatalog,
            bundle: DefaultSystemBundle(),
            appDistribution: DefaultAppDistribution()
        )
        #endif
    }

    #if QURAN_SYNC
    /// Starts the Quran.com sign-in from the What's New sync reveal, like the sign-in toast and Settings do.
    private static func signInToQuranCom(
        on viewController: UIViewController,
        authenticationClient: any AuthenticationClient,
        analytics: AnalyticsLibrary
    ) async {
        analytics.quranSyncSignIn(from: .whatsNew)
        logger.info("Quran Sync: starting sign in from What's New")
        do {
            try await authenticationClient.login(on: viewController)
            let state = await authenticationClient.authenticationState
            logger.info("Quran Sync: sign in completed from What's New. State: \(state)")
            if state == .authenticated {
                SyncSignInNudge.stopAfterSignIn()
            }
        } catch AuthenticationClientError.cancelled {
            logger.info("Quran Sync: sign in cancelled from What's New")
        } catch {
            logger.error("Quran Sync: failed to sign in from What's New: \(error)")
            viewController.showErrorAlert(error: error)
        }
    }
    #endif
}

@MainActor
private final class AppViewControllerReference {
    weak var value: AppViewController?
}
