//
//  Container.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import Analytics
import AppDependencies
import AuthenticationClient
import BatchDownloader
import CoreDataModel
import CoreDataPersistence
import Foundation
import LastPagePersistence
#if QURAN_SYNC
    import MobileSync
#endif
import NotePersistence
import PageBookmarkPersistence
import ReadingService
import UIKit
import VLogging

/// Hosts singleton dependencies
class Container: AppDependencies {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = Container()

    let remoteResources: ReadingRemoteResources? = nil
    private(set) lazy var readingResources = ReadingResourcesService(downloader: downloadManager, remoteResources: remoteResources)

    let analytics: AnalyticsLibrary = LoggingAnalyticsLibrary()

    private(set) lazy var lastPagePersistence: LastPagePersistence = CoreDataLastPagePersistence(stack: coreDataStack)
    private(set) lazy var pageBookmarkPersistence: PageBookmarkPersistence = CoreDataPageBookmarkPersistence(stack: coreDataStack)

    private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)
    #if QURAN_SYNC
        private(set) lazy var quranDataService: QuranDataService = syncAppGraph.quranDataService

        private(set) lazy var authenticationClient: (any AuthenticationClient)? = {
            let authService = syncAppGraph.authService
            let quranDataService = syncAppGraph.quranDataService
            return AuthenticationClientMobileSyncImpl(authService: authService, quranDataService: quranDataService)
        }()
    #else
        let authenticationClient: (any AuthenticationClient)? = nil
    #endif

    private(set) lazy var downloadManager: DownloadManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "DownloadsBackgroundIdentifier")
        configuration.timeoutIntervalForRequest = 60 * 5 // 5 minutes
        return DownloadManager(
            maxSimultaneousDownloads: 600,
            configuration: configuration,
            downloadsURL: Constant.databasesURL.appendingPathComponent("downloads.db", isDirectory: false)
        )
    }()

    var databasesURL: URL { Constant.databasesURL }
    var wordsDatabase: URL { Constant.wordsDatabase }
    var filesAppHost: URL { Constant.filesAppHost }
    var quranProfileURL: URL { Self.quranProfileURL() }
    var appHost: URL { Constant.appHost }
    var databasesDirectory: URL { Constant.databasesURL }
    var logsDirectory: URL { FileManager.documentsURL.appendingPathComponent("logs") }

    var supportsCloudKit: Bool { false }

    // MARK: Private

    #if QURAN_SYNC
        private static let mobileSyncRedirectURI = "com.quran.oauth://callback"
        private static let mobileSyncScopes = [
            "openid",
            "offline_access",
            "content",
            "user",
            "bookmark",
            "sync",
            "collection",
            "reading_session",
            "preference",
            "note",
        ]

        private lazy var syncAppGraph: AppGraph = {
            let authConfig = Self.mobileSyncAuthConfiguration()
            let synchronizationEnvironment = Self.makeSynchronizationEnvironment(usePreProduction: Self.usePreProductionSyncEnvironment())

            AuthFlowFactoryProvider.shared.doInitialize()

            let driverFactory = DriverFactory()
            let storage = AppleMobileSyncStorageFactory.shared.create()
            let graph = SharedDependencyGraph.shared.doInit(
                driverFactory: driverFactory,
                storage: storage,
                environment: synchronizationEnvironment,
                authConfig: authConfig
            )

            return graph
        }()

        private static func mobileSyncAuthConfiguration() -> AuthConfig {
            let clientID = nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_ID") ?? "stub-value"
            if clientID == "stub-value" {
                logger.info("Using stubbed client ID for sync")
            }

            let usePreProduction = usePreProductionSyncEnvironment()
            let authEnvironment: AuthEnvironment = usePreProduction ? .prelive : .production

            return AuthConfig(
                environment: authEnvironment,
                clientId: clientID,
                clientSecret: nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_SECRET"),
                redirectUri: mobileSyncRedirectURI,
                postLogoutRedirectUri: mobileSyncRedirectURI,
                scopes: mobileSyncScopes
            )
        }

        private static func makeSynchronizationEnvironment(usePreProduction: Bool) -> SynchronizationEnvironment {
            let endpoint = usePreProduction
                ? "https://apis-prelive.quran.foundation/auth"
                : "https://apis.quran.foundation/auth"
            return SynchronizationEnvironment(endPointURL: endpoint)
        }
    #endif

    private lazy var coreDataStack: CoreDataStack = {
        let stack = CoreDataStack(name: "Quran", modelUrl: CoreDataModelResources.quranModel) {
            let lastPage = CoreDataLastPageUniquifier()
            let pageBookmark = CoreDataPageBookmarkUniquifier()
            let note = CoreDataNoteUniquifier()
            return [lastPage, pageBookmark, note]
        }
        return stack
    }()

    private static func nonEmptyEnvironmentValue(_ key: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func quranProfileURL() -> URL {
        let url = usePreProductionSyncEnvironment()
            ? "https://prelive.quran.com/profile"
            : "https://quran.com/profile"
        return URL(validURL: url)
    }

    private static func usePreProductionSyncEnvironment() -> Bool {
        guard let environment = nonEmptyEnvironmentValue("QURAN_OAUTH_ENVIRONMENT") else {
            return true
        }
        return environment.lowercased() != "production"
    }
}

private enum Constant {
    static let wordsDatabase = Bundle.main
        .url(forResource: "words", withExtension: "db")!

    static let appHost: URL = .init(validURL: "https://quran.app/")

    static let filesAppHost: URL = .init(validURL: "https://files.quran.app/")

    static let databasesURL = FileManager.documentsURL
        .appendingPathComponent("databases", isDirectory: true)
}
