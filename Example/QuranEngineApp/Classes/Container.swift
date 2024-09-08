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
    private(set) lazy var pageBookmarkPersistence: PageBookmarkPersistence = CoreDataPageBookmarkPersistence(stack: coreDataStack)
    private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)

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
    
    // MARK: Public
    func handleIncomingUrl(urlContext: UIOpenURLContext) {
        let url = urlContext.url
        
        if url.scheme == "quran" || url.scheme == "quran-ios" {
            let path: String
            
            if #available(iOS 16.0, *) {
                path = url.path(percentEncoded: true)
            } else {
                path = url.path
            }
            
            _ = navigateTo(path: path)
        }
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
    
    private func navigateTo(path: String) -> Bool {
        // Implement the actual navigation or handling logic in follow up pr
        return true
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
