//
//  LocalTranslationsRetriever.swift
//
//
//  Created by Afifi, Mohamed on 10/29/21.
//

import Foundation
import QuranText
import SystemDependencies
import VerseTextPersistence

public struct LocalTranslationsRetriever {
    let persistence: ActiveTranslationsPersistence
    let versionUpdater: TranslationsVersionUpdater

    public init(databasesURL: URL, fileSystem: FileSystem = DefaultFileSystem()) {
        let versionPersistenceFactory = { (translation: Translation) in
            GRDBDatabaseVersionPersistence(fileURL: translation.localURL)
        }

        self.init(databasesURL: databasesURL, fileSystem: fileSystem,
                  versionPersistenceFactory: versionPersistenceFactory)
    }

    init(databasesURL: URL, fileSystem: FileSystem,
         versionPersistenceFactory: @escaping VersionPersistenceFactory)
    {
        persistence = GRDBActiveTranslationsPersistence(directory: databasesURL)
        versionUpdater = TranslationsVersionUpdater(
            persistence: persistence,
            versionPersistenceFactory: versionPersistenceFactory,
            unzipper: DefaultTranslationUnzipper(),
            fileSystem: fileSystem
        )
    }

    public func getLocalTranslations() async throws -> [Translation] {
        let translations = try await persistence.retrieveAll()

        return try await withThrowingTaskGroup(of: Translation.self) { group in
            for translation in translations {
                group.addTask {
                    try await updateInstalledVersion(of: translation)
                }
            }
            let result = try await group.collect()
            return result.sortedAs(translations.map(\.id), by: \.id)
        }
    }

    private func updateInstalledVersion(of translation: Translation) async throws -> Translation {
        try await versionUpdater.updateInstalledVersion(for: translation)
    }
}
