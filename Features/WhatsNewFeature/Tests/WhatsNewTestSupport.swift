//
//  WhatsNewTestSupport.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import Analytics
import AnalyticsFake
import AppMigrator
#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
#endif
import NoorUI
import UIKit
@testable import WhatsNewFeature

/// Builds the controller with a real store and fakes at the platform boundaries.
@MainActor
enum WhatsNewControllerFactory {
    // MARK: Internal

    #if QURAN_SYNC
    static func make(
        analytics: AnalyticsLibrary = AnalyticsLibrarySpy(),
        authenticationClient: any AuthenticationClient = AuthenticationClientFake(),
        launchVersion: LaunchVersionUpdate
    ) -> AppWhatsNewController {
        AppWhatsNewController(
            analytics: analytics,
            launchVersion: launchVersion,
            appIconCatalog: appIconCatalog,
            authenticationClient: authenticationClient
        )
    }
    #else
    static func make(
        analytics: AnalyticsLibrary = AnalyticsLibrarySpy(),
        launchVersion: LaunchVersionUpdate
    ) -> AppWhatsNewController {
        AppWhatsNewController(analytics: analytics, launchVersion: launchVersion, appIconCatalog: appIconCatalog)
    }
    #endif

    // MARK: Private

    private static let appIconCatalog = AppIconCatalog(sections: [
        .init(id: "all", title: "All", previewSize: .large, options: [
            AppIconOption(
                id: "primary",
                alternateIconName: nil,
                name: "Primary",
                previewImageName: "app-icon-primary",
                accent: AppIconAccent(light: .systemIndigo, dark: .systemYellow, onDark: .black)
            ),
        ]),
    ])
}

/// Presents and dismisses without UIKit transitions, which never finish in unit tests.
/// Dismissal completes right away, like a finished transition.
final class PresenterFake: UIViewController {
    private(set) var presentedController: UIViewController?
    private(set) var dismissCount = 0

    override func present(_ viewController: UIViewController, animated _: Bool, completion: (() -> Void)? = nil) {
        presentedController = viewController
        completion?()
    }

    override func dismiss(animated _: Bool, completion: (() -> Void)? = nil) {
        dismissCount += 1
        presentedController = nil
        completion?()
    }
}
