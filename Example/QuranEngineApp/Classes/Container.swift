//
//  Container.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import Analytics
import AppDependencies
import BatchDownloader
import CoreDataModel
import CoreDataPersistence
import LastPagePersistence
import NotePersistence
import PageBookmarkPersistence
import ReadingService

actor DownloadManagerContainer {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = DownloadManagerContainer()

    func downloadManager() async -> DownloadManager {
        if let downloader {
            return downloader
        }
        let downloader = await buildDownloadManager()
        self.downloader = downloader
        return downloader
    }

    // MARK: Private

    private var downloader: DownloadManager?

    private nonisolated func buildDownloadManager() async -> DownloadManager {
        let configuration = URLSessionConfiguration.background(withIdentifier: "DownloadsBackgroundIdentifier")
        configuration.timeoutIntervalForRequest = 60 * 5 // 5 minutes
        return await DownloadManager(
            maxSimultaneousDownloads: 600,
            configuration: configuration,
            downloadsURL: Constant.databasesURL.appendingPathComponent("downloads.db", isDirectory: false)
        )
    }
}

/// Hosts singleton dependencies
class Container: AppDependencies {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = Container()

    let readingResources = ReadingResourcesService()
    let analytics: AnalyticsLibrary = LoggingAnalyticsLibrary()

    private(set) lazy var lastPagePersistence: LastPagePersistence = CoreDataLastPagePersistence(stack: coreDataStack)
    private(set) lazy var pageBookmarkPersistence: PageBookmarkPersistence = CoreDataPageBookmarkPersistence(stack: coreDataStack)
    private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)

    var databasesURL: URL { Constant.databasesURL }
    var wordsDatabase: URL { Constant.wordsDatabase }
    var filesAppHost: URL { Constant.filesAppHost }
    var appHost: URL { Constant.appHost }

    var supportsCloudKit: Bool { false }

    func downloadManager() async -> DownloadManager {
        let container = DownloadManagerContainer.shared
        return await container.downloadManager()
    }

    // MARK: Private

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
    static let wordsDatabase = Bundle.main
        .url(forResource: "words", withExtension: "db")!

    static let appHost: URL = URL(validURL: "https://quran.app/")

    static let filesAppHost: URL = URL(validURL: "https://files.quran.app/")

    static let databasesURL = FileManager.documentsURL
        .appendingPathComponent("databases", isDirectory: true)
}
