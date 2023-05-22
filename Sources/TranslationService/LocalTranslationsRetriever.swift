//
//  LocalTranslationsRetriever.swift
//
//
//  Created by Afifi, Mohamed on 10/29/21.
//

import Foundation
import PromiseKit
import SystemDependencies

public struct LocalTranslationsRetriever {
    let persistence: ActiveTranslationsPersistence
    let versionUpdater: TranslationsVersionUpdater

    public init(databasesPath: String, fileSystem: FileSystem = DefaultFileSystem()) {
        let versionPersistenceFactory = { (translation: Translation) in
            try GRDBDatabaseVersionPersistence(fileURL: translation.localURL)
        }

        self.init(databasesPath: databasesPath, fileSystem: fileSystem,
                  versionPersistenceFactory: versionPersistenceFactory)
    }

    init(databasesPath: String, fileSystem: FileSystem,
         versionPersistenceFactory: @escaping VersionPersistenceFactory)
    {
        persistence = GRDBActiveTranslationsPersistence(directory: databasesPath)
        versionUpdater = TranslationsVersionUpdater(
            persistence: persistence,
            versionPersistenceFactory: versionPersistenceFactory,
            unzipper: DefaultTranslationUnzipper(),
            fileSystem: fileSystem
        )
    }

    public func getLocalTranslations() -> Promise<[Translation]> {
        DispatchQueue.global().asyncPromise {
            try await getLocalTranslations()
        }
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
