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
        print("Documents directory: ", FileManager.documentsURL)

        FontName.registerFonts()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)

        Task {
            // Eagerly load download manager to handle any background downloads.
            await container.downloadManager.start()

            // Begin fetching resources immediately after download manager is initialized.
            await container.readingResources.startLoadingResources()
        }

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
        let downloadManager = container.downloadManager
        downloadManager.setBackgroundSessionCompletion(completionHandler)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Check if the URL scheme matches the custom scheme
        if url.scheme == "quran-ios" {
            // Parse the URL to determine the desired action
            let path = url.host ?? ""
            
            // Implement custom logic to navigate to a specific view or perform an action
            // Example: Navigate to a specific surah or ayah
            handleCustomURL(path: path)
            
            return true
        }
        return false
    }

    private func handleCustomURL(path: String) {
        // Example logic to handle the custom URL path
        // This could involve navigating to a specific part of the app
        // For instance, opening a specific Surah or Ayah
    }

    // MARK: Private

    private let container = Container.shared
}
