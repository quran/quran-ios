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
        MobileSyncPageBookmarkPersistence(session: mobileSyncSession, legacyStack: coreDataStack)
    }()
    private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)
    private(set) lazy var authenticationClient: (any AuthenticationClient)? = {
        guard Constant.QuranOAuthAppConfigurations != nil else {
            return nil
        }
        return AuthenticationClientMobileSyncImpl(session: mobileSyncSession)
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

    private lazy var mobileSyncSession = MobileSyncSession(configurations: Constant.QuranOAuthAppConfigurations)

    private lazy var coreDataStack: CoreDataStack = {
        let stack = CoreDataStack(name: "Quran", modelUrl: CoreDataModelResources.quranModel) {
            let lastPage = CoreDataLastPageUniquifier()
            let pageBookmark = CoreDataPageBookmarkUniquifier()
            let note = CoreDataNoteUniquifier()
            return [lastPage, pageBookmark, note]
        }
        return stack
    }()
}

private enum Constant {
    private static let environment = ProcessInfo.processInfo.environment

    static let wordsDatabase = Bundle.main
        .url(forResource: "words", withExtension: "db")!

    static let appHost: URL = URL(validURL: "https://quran.app/")

    static let filesAppHost: URL = URL(validURL: "https://files.quran.app/")

    static let databasesURL = FileManager.documentsURL
        .appendingPathComponent("databases", isDirectory: true)

    /// Reads Quran.com OAuth configuration from environment variables.
    static let QuranOAuthAppConfigurations: AuthenticationClientConfiguration? = {
        guard
            let clientID = nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_ID"),
            let issuerURL = URL(string: nonEmptyEnvironmentValue("QURAN_OAUTH_ISSUER_URL") ?? "")
        else {
            return nil
        }
        guard
            let redirectURL = URL(string: nonEmptyEnvironmentValue("QURAN_OAUTH_REDIRECT_URL") ?? "com.quran.oauth://callback")
        else {
            return nil
        }

        let clientSecret = nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_SECRET") ?? ""
        let scopes = nonEmptyEnvironmentValue("QURAN_OAUTH_SCOPES")?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? [
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

        return AuthenticationClientConfiguration(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURL: redirectURL,
            scopes: scopes,
            authorizationIssuerURL: issuerURL
        )
    }()

    private static func nonEmptyEnvironmentValue(_ key: String) -> String? {
        guard let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}
