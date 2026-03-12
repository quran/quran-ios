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
import NotePersistence
import PageBookmarkPersistence
import ReadingService
import UIKit

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
    private(set) lazy var pageBookmarkPersistence: PageBookmarkPersistence = {
        #if QURAN_SYNC
            if let mobileSyncSession {
                return MobileSyncPageBookmarkPersistence(session: mobileSyncSession)
            }
        #endif
        return CoreDataPageBookmarkPersistence(stack: coreDataStack)
    }()

    private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)
    private(set) lazy var authenticationClient: (any AuthenticationClient)? = {
        #if QURAN_SYNC
            if let mobileSyncSession {
                return AuthenticationClientMobileSyncImpl(session: mobileSyncSession)
            }
        #endif

        guard let configurations = Self.quranOAuthConfiguration() else {
            return nil
        }

        return AuthenticationClientImpl(configurations: configurations)
    }()

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
    var appHost: URL { Constant.appHost }
    var databasesDirectory: URL { Constant.databasesURL }
    var logsDirectory: URL { FileManager.documentsURL.appendingPathComponent("logs") }

    var supportsCloudKit: Bool { false }

    // MARK: Private

    #if QURAN_SYNC
        private lazy var mobileSyncSession: MobileSyncSession? = {
            guard let clientID = Container.nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_ID") else {
                return nil
            }
            let clientSecret = Container.nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_SECRET")
            return MobileSyncSession(
                clientID: clientID,
                clientSecret: clientSecret,
                usePreProduction: Self.usePreProductionSyncEnvironment()
            )
        }()
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

    private static func quranOAuthConfiguration() -> AuthenticationClientConfiguration? {
        guard
            let clientID = nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_ID"),
            let issuerURL = URL(string: nonEmptyEnvironmentValue("QURAN_OAUTH_ISSUER_URL") ?? ""),
            let redirectURL = URL(string: nonEmptyEnvironmentValue("QURAN_OAUTH_REDIRECT_URL") ?? ""),
            let scopesValue = nonEmptyEnvironmentValue("QURAN_OAUTH_SCOPES")
        else {
            return nil
        }

        let scopes = scopesValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !scopes.isEmpty else {
            return nil
        }

        return AuthenticationClientConfiguration(
            clientID: clientID,
            clientSecret: nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_SECRET") ?? "",
            redirectURL: redirectURL,
            scopes: scopes,
            authorizationIssuerURL: issuerURL
        )
    }

    private static func nonEmptyEnvironmentValue(_ key: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func usePreProductionSyncEnvironment() -> Bool {
        guard let issuer = nonEmptyEnvironmentValue("QURAN_OAUTH_ISSUER_URL")?.lowercased() else {
            return false
        }
        return issuer.contains("staging") || issuer.contains("preprod") || issuer.contains("prelive") || issuer.contains("dev")
    }
}

private enum Constant {
    static let wordsDatabase = Bundle.main
        .url(forResource: "words", withExtension: "db")!

    static let appHost: URL = URL(validURL: "https://quran.app/")

    static let filesAppHost: URL = URL(validURL: "https://files.quran.app/")

    static let databasesURL = FileManager.documentsURL
        .appendingPathComponent("databases", isDirectory: true)
}
