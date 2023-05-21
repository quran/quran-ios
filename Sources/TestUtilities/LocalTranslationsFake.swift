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
    public let persistence: SQLiteActiveTranslationsPersistence

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

    public func setTranslations(_ translations: [Translation]) throws {
        let oldTranslations = try persistence.retrieveAll()
        for oldTranslation in oldTranslations {
            try persistence.remove(oldTranslation)
        }
        for translation in translations {
            try persistence.insert(translation)
        }
        preferences.selectedTranslations = translations.map(\.id)
        fileSystem.files = Set(translations.map(\.localURL))
    }

    public func insertTranslation(_ translation: Translation, installedVersion: Int?, downloaded: Bool) throws {
        var translation = translation
        translation.installedVersion = installedVersion
        try persistence.insert(translation)

        if installedVersion != nil {
            preferences.toggleSelection(translation.id)
        }

        if downloaded {
            fileSystem.files.insert(translation.localURL)
        }
    }
}
