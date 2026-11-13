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
#if QURAN_SYNC
import SyncLogging
#endif
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Internal

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Documents directory: ", FileManager.documentsURL)

        if #available(iOS 17.2, *) {
            QuranAppShortcuts.updateAppShortcutParameters()
        }
        FontName.registerFonts()
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = .debug
            return handler
        }
        #if QURAN_SYNC
        MobileSyncLogBridge.install(level: .debug)
        #endif

        startResourcesIfAvailable()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        startResourcesIfAvailable()
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        pendingBackgroundSessionCompletion = completionHandler
        startResourcesIfAvailable()
    }

    // MARK: Private

    private let container = Container.shared
    private var resourceStartupTask: Task<Void, Never>?
    private var pendingBackgroundSessionCompletion: (() -> Void)?

    private func startResourcesIfAvailable() {
        // A background Siri launch can precede unlock. Opening the downloads database then
        // would lose its saved batches because the download manager cannot retry startup.
        guard UIApplication.shared.isProtectedDataAvailable else { return }

        if let completion = pendingBackgroundSessionCompletion {
            pendingBackgroundSessionCompletion = nil
            // Install this before creating the session, which can deliver its events immediately.
            container.downloadManager.setBackgroundSessionCompletion(completion)
        }
        guard resourceStartupTask == nil else { return }
        resourceStartupTask = Task {
            do {
                try await container.startDownloads()
            } catch {
                // Protected data may become unavailable before the task starts; retry on unlock.
                resourceStartupTask = nil
                return
            }
            await container.readingResources.startLoadingResources()
        }
    }
}
