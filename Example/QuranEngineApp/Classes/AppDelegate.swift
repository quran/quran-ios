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
import Shared
import Combine
import AuthenticationClient

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Internal

    private var syncAgent: Shared.SynchronizationClient!
    private var cancellable: Cancellable?
    private var mainRepo: Any?
    private var collector: Any?
    private var pipeline: Any?

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

        setupPipeline()

        self.syncAgent.applicationStarted()

        return true
    }

    private func setupPipeline() {
        let driverFactory = DriverFactory()
//        let mainRepo = Shared.PageBookmarksRepositoryFactory
//            .companion
//            .createRepository(driverFactory: driverFactory)
        let syncRepo = Shared.PageBookmarksRepositoryFactory
            .companion
            .createSynchronizationRepository(driverFactory: driverFactory)

        let pipeline = Shared.SyncEnginePipeline.init(bookmarksRepository: syncRepo)
        self.syncAgent = pipeline.setup(
            environment: SynchronizationEnvironment(endPointURL: "https://apis-testing.quran.foundation"),
            localModificationDateFetcher: ModificationDateFetcher(),
            authenticationDataFetcher: AuthDataFetcher(authClient: container.authenticationClient!),
            callback: Callbacks()
        )

        self.pipeline = pipeline

        NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "bookmarksupdated"),
                                               object: nil,
                                               queue: nil) { notificatio in
            print("AppDelegate - bookmarksupdated's notification")
            self.syncAgent.localDataUpdated()
        }
    }

    class Callbacks: NSObject, SyncEngineCallback {

        func encounteredError(errorMsg: String) {
            Task { @MainActor in
                let view = UIAlertController(title: "Sync Error",
                                             message: errorMsg,
                                             preferredStyle: .alert)
                view.addAction(.init(title: "Ok", style: .cancel))
                (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.rootViewController?.present(view, animated: true)
            }
        }
        
        func synchronizationDone(newLastModificationDate: Int64) {
            print("Pipeline reported success- \(newLastModificationDate)}")
            UserDefaults.standard.set(newLastModificationDate, forKey: "last-date")
        }
    }

    //****
    //\/\/\/\/
    //****

    private class Collector: NSObject, Kotlinx_coroutines_coreFlowCollector {

        let subject: any Subject<Void, Error>

        init(subject: any Subject<Void, Error>) {
            self.subject = subject
        }

        func emit(value: Any?, completionHandler: @escaping ((any Error)?) -> Void) {
            print("AppDelegate - Got values: \(value ?? [])")
            subject.send(())
        }
    }


    class ModificationDateFetcher: NSObject, Shared.LocalModificationDateFetcher {
        func localLastModificationDate(completionHandler: @escaping (KotlinLong?, (any Error)?) -> Void) {
            // Feed 0 for now.
            let val = KotlinLong(value: UserDefaults.standard.value(forKey: "last-date") as? Int64 ?? 0)
            completionHandler(val, nil)
        }
    }

    class AuthDataFetcher: NSObject, Shared.AuthenticationDataFetcher {

        let authClient: AuthenticationClient
        init(authClient: AuthenticationClient) {
            self.authClient = authClient
        }

        func fetchAuthenticationHeaders(completionHandler: @escaping ([String : String]?, (any Error)?) -> Void) {
            Task { @MainActor in
                let state = try await authClient.restoreState()
                print("State restored for syncing: \(state)")
                Task {
                    do {
                        let headers = try await authClient.getAuthenticationHeaders()
                        print(headers)
                        completionHandler(headers, nil)
                    }
                    catch {
                        completionHandler(nil, error)
                    }
                }
            }
        }
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

    // MARK: Private

    private let container = Container.shared
}
