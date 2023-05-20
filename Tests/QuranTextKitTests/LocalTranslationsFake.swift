//
//  LocalTranslationsFake.swift
//  
//
//  Created by Mohamed Afifi on 2023-05-20.
//

import Foundation
@testable import TranslationService
import SystemDependenciesFake

struct LocalTranslationsFake {
    let databasesPath = FileManager.documentsPath.stringByAppendingPath("databases")
    let preferences = SelectedTranslationsPreferences.shared

    let fileSystem = FileSystemFake()
    let retriever: LocalTranslationsRetriever
    let persistence: SQLiteActiveTranslationsPersistence


    init() {
        persistence = SQLiteActiveTranslationsPersistence(directory: databasesPath)
        retriever = LocalTranslationsRetriever(databasesPath: databasesPath, fileSystem: fileSystem)
    }

    func tearDown() {
        try? FileManager.default.removeItem(atPath: databasesPath)
    }

    func setTranslations(_ translations: [Translation]) throws {
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
}
