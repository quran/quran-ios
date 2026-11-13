//
//  Container.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import Analytics
import AppDependencies
import AppStructureFeature
import BatchDownloader
import CoreDataModel
import CoreDataPersistence
import Foundation
import LastPagePersistence
#if QURAN_SYNC
import AuthenticationClient
import LegacyDataMigration
import LegacyDataPersistence
import MobileSync
#endif
import NoorUI
import NotePersistence
import PageBookmarkPersistence
import QuranAudioKit
import QuranKit
import ReadingService
import UIKit
import VLogging

/// Hosts singleton dependencies
class Container: AppDependencies {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = Container()

    @MainActor private(set) lazy var launchPreparation = LaunchPreparation(container: self)
    @MainActor var playbackService: QuranPlaybackService {
        if let storedPlaybackService { return storedPlaybackService }
        let service = QuranPlaybackService(
            downloader: QuranAudioDownloader(baseURL: filesAppHost, downloader: downloadManager)
        )
        storedPlaybackService = service
        return service
    }

    @MainActor private var storedPlaybackService: QuranPlaybackService?
    @MainActor private var siriRequestGeneration: UInt = 0

    @MainActor
    func continueListening(pageCount: Int) async throws {
        try Task.checkCancellation()
        siriRequestGeneration &+= 1
        let request = siriRequestGeneration
        // Do not construct the player or its stores before protected-data preparation.
        let playbackGeneration = storedPlaybackService?.commandGeneration ?? 0
        try await launchPreparation.prepare()
        try Task.checkCancellation()
        await startDownloads()
        let quran = ReadingPreferences.shared.reading.quran
        var fallback = quran.firstVerse
        for try await pages in lastPageService().lastPages(quran: quran) {
            fallback = pages.first?.page.firstVerse ?? quran.firstVerse
            break
        }
        try Task.checkCancellation()
        guard request == siriRequestGeneration,
              playbackService.commandGeneration == playbackGeneration
        else { throw CancellationError() }
        try await playbackService.continueListening(quran: quran, fallback: fallback, pageCount: pageCount)
    }

    @MainActor
    func startDownloads() async {
        if downloadsStartupTask == nil {
            let manager = downloadManager
            downloadsStartupTask = Task { await manager.start() }
        }
        await downloadsStartupTask?.value
    }

    @MainActor private var downloadsStartupTask: Task<Void, Never>?

    let remoteResources: ReadingRemoteResources? = nil
    private(set) lazy var readingResources = ReadingResourcesService(downloader: downloadManager, remoteResources: remoteResources)

    let analytics: AnalyticsLibrary = LoggingAnalyticsLibrary()

    private(set) lazy var coreDataStack: CoreDataStack = {
        let stack = CoreDataStack(name: "Quran", modelUrl: CoreDataModelResources.quranModel) {
            let lastPage = CoreDataLastPageUniquifier()
            let pageBookmark = CoreDataPageBookmarkUniquifier()
            return [lastPage, pageBookmark]
        }
        return stack
    }()

    private(set) lazy var lastPagePersistence: LastPagePersistence = CoreDataLastPagePersistence(stack: coreDataStack)
    private(set) lazy var pageBookmarkPersistence: PageBookmarkPersistence = CoreDataPageBookmarkPersistence(stack: coreDataStack)

    private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)

    let appIconCatalog = AppIconCatalog.example

    #if QURAN_SYNC
    private(set) lazy var quranDataService: MobileSyncDataService = syncGraph.dataService

    private(set) lazy var authenticationClient: any AuthenticationClient = AuthenticationClientMobileSyncImpl(
        authService: syncGraph.authService
    )

    private(set) lazy var legacyDataImportCoordinator = LegacyDataImportCoordinator(
        reader: CoreDataLegacyDataReader(stack: coreDataStack),
        quranDataService: quranDataService
    )
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
    var isDebugLoggingAlwaysEnabled: Bool { true }

    var supportsCloudKit: Bool { false }

    // MARK: Private

    #if QURAN_SYNC
    /// Without `QURAN_OAUTH_CLIENT_ID`, sign-in is unavailable and data stays local.
    private lazy var syncGraph = MobileSyncGraph.shared(
        environment: Self.usePreProductionSyncEnvironment() ? .prelive : .production,
        clientID: Self.nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_ID") ?? "",
        clientSecret: Self.nonEmptyEnvironmentValue("QURAN_OAUTH_CLIENT_SECRET")
    )
    #endif

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
