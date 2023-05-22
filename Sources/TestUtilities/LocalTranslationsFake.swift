//
//  LocalTranslationsFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-20.
//

import Foundation
import SystemDependenciesFake
@testable import TranslationService

public struct LocalTranslationsFake {
    public static let databasesPath = FileManager.documentsPath.stringByAppendingPath("databases")

    let preferences = SelectedTranslationsPreferences.shared
    public let fileSystem = FileSystemFake()
    public let persistence: ActiveTranslationsPersistence

    public let retriever: LocalTranslationsRetriever

    public init(useFactory: Bool = false) {
        persistence = SQLiteActiveTranslationsPersistence(directory: Self.databasesPath)
        if useFactory {
            let persistenceFactory = { (translation: Translation) -> DatabaseVersionPersistence in
                let url = TestResources.resourceURL(translation.fileName)
                return SQLiteDatabaseVersionPersistence(filePath: url.path)
            }
            retriever = LocalTranslationsRetriever(databasesPath: Self.databasesPath, fileSystem: fileSystem, versionPersistenceFactory: persistenceFactory)
        } else {
            retriever = LocalTranslationsRetriever(databasesPath: Self.databasesPath, fileSystem: fileSystem)
        }
    }

    public func tearDown() {
        try? FileManager.default.removeItem(atPath: Self.databasesPath)
    }

    public func setTranslations(_ translations: [Translation]) async throws {
        let oldTranslations = try await persistence.retrieveAll()
        for oldTranslation in oldTranslations {
            try await persistence.remove(oldTranslation)
        }
        for translation in translations {
            try await persistence.insert(translation)
        }
        preferences.selectedTranslations = translations.map(\.id)
        fileSystem.files = Set(translations.map(\.localURL))
    }

    public func insertTranslation(_ translation: Translation,
                                  installedVersion: Int?,
                                  downloaded: Bool) async throws
    {
        var translation = translation
        translation.installedVersion = installedVersion
        try await persistence.insert(translation)

        if installedVersion != nil {
            preferences.toggleSelection(translation.id)
        }

        if downloaded {
            fileSystem.files.insert(translation.localURL)
        }
    }
}
