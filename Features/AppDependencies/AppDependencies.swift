//
//  AppDependencies.swift
//
//
//  Created by Mohamed Afifi on 2023-06-18.
//

import Analytics
import AnnotationsService
import BatchDownloader
import Foundation
import NotePersistence
import PageBookmarkPersistence
import QuranTextKit

public protocol AppDependencies {
    var databasesURL: URL { get }
    var quranUthmaniV2Database: URL { get }
    var wordsDatabase: URL { get }
    var filesAppHost: URL { get }

    func downloadManager() async -> DownloadManager

    var analytics: AnalyticsLibrary { get }
    var notePersistence: NotePersistence { get }
    var pageBookmarkPersistence: PageBookmarkPersistence { get }
}

extension AppDependencies {
    public func textDataService() -> QuranTextDataService {
        QuranTextDataService(
            databasesURL: databasesURL,
            quranFileURL: quranUthmaniV2Database
        )
    }

    public func noteService() -> NoteService {
        NoteService(
            persistence: notePersistence,
            textService: textDataService(),
            analytics: analytics
        )
    }
}
