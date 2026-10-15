//
//  LocalTranslationsFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-20.
//

import Foundation
import QuranText
import SystemDependenciesFake
import TestResources
import TranslationPersistence
import VerseTextPersistence
@testable import TranslationService

public struct LocalTranslationsFake {
    // MARK: Lifecycle

    public init(useFactory: Bool = false) {
        // Each fake gets its own directory: `DatabaseConnection` pools connections by URL for the
        // whole process, so a shared path can hand a test a stale connection with rows from an earlier test.
        databasesURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalTranslationsFake-\(UUID().uuidString)", isDirectory: true)
        persistence = GRDBActiveTranslationsPersistence(directory: databasesURL)
        if useFactory {
            let persistenceFactory = { (translation: Translation) in
                let url = TestResources.resourceURL(translation.fileName)
                return GRDBDatabaseVersionPersistence(fileURL: url)
            }
            retriever = LocalTranslationsRetriever(databasesURL: databasesURL, fileSystem: fileSystem, versionPersistenceFactory: persistenceFactory)
        } else {
            retriever = LocalTranslationsRetriever(databasesURL: databasesURL, fileSystem: fileSystem)
        }
    }

    // MARK: Public

    public let databasesURL: URL

    public let fileSystem = FileSystemFake()
    public let persistence: ActiveTranslationsPersistence

    public let retriever: LocalTranslationsRetriever

    public func tearDown() {
        try? FileManager.default.removeItem(at: databasesURL)
    }

    public func setTranslations(_ translations: [Translation]) async throws {
        let oldTranslations = try await persistence.retrieveAll()
        for oldTranslation in oldTranslations {
            try await persistence.remove(oldTranslation)
        }
        for translation in translations {
            try await persistence.insert(translation)
        }
        preferences.selectedTranslationIds = translations.map(\.id)
        fileSystem.files = Set(translations.map(\.localPath.url))
    }

    public func insertTranslation(
        _ translation: Translation,
        installedVersion: Int?,
        downloaded: Bool
    ) async throws {
        var translation = translation
        translation.installedVersion = installedVersion
        try await persistence.insert(translation)

        if installedVersion != nil {
            preferences.toggleSelection(translation.id)
        }

        if downloaded {
            fileSystem.files.insert(translation.localPath.url)
        }
    }

    // MARK: Internal

    let preferences = SelectedTranslationsPreferences.shared
}
