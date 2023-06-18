//
//  AppDependencies.swift
//
//
//  Created by Mohamed Afifi on 2023-06-18.
//

import Analytics
import AnnotationsService
import Foundation
import NotePersistence
import QuranTextKit

public protocol AppDependencies {
    var databasesURL: URL { get }
    var quranUthmaniV2Database: URL { get }
    var wordsDatabase: URL { get }

    var analytics: AnalyticsLibrary { get }
    var notePersistence: NotePersistence { get }
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
