//
//  AppDelegate.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import AppStructureFeature
import Logging
import NoorFont
import NoorUI
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Internal

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FontName.registerFonts()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        AsyncTextLabelSystem.bootstrap(FixedTextNode.init)

        // Eagerly load download manager to handle any background downloads.
        Task { _ = await downloadManagerContainer.downloadManager() }

        // Begin fetching resources immediately upon the application's start-up.
        Task { await container.readingResources.startLoadingResources() }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            let downloadManager = await downloadManagerContainer.downloadManager()
            downloadManager.setBackgroundSessionCompletion(completionHandler)
        }
    }

    // MARK: Private

    private let container = Container.shared
    private let downloadManagerContainer = DownloadManagerContainer.shared
}
