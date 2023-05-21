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
            SQLiteDatabaseVersionPersistence(filePath: translation.localURL.path)
        }

        self.init(databasesPath: databasesPath, fileSystem: fileSystem,
                  versionPersistenceFactory: versionPersistenceFactory)
    }

    init(databasesPath: String, fileSystem: FileSystem,
         versionPersistenceFactory: @escaping VersionPersistenceFactory)
    {
        persistence = SQLiteActiveTranslationsPersistence(directory: databasesPath)
        versionUpdater = DefaultTranslationsVersionUpdater(
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
        let translations = try persistence.retrieveAll()

        return try await withThrowingTaskGroup(of: Translation.self) { group in
            for translation in translations {
                group.addTask {
                    try await updateInstalledVersion(of: translation)
                }
            }
            let result = try await group.collect()
            return result.sortedAs(translations)
        }
    }

    private func updateInstalledVersion(of translation: Translation) async throws -> Translation {
        try versionUpdater.updateInstalledVersion(for: translation)
    }
}
