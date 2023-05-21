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
        persistence = SQLiteActiveTranslationsPersistence(directory: databasesPath)
        let versionFactory = VersionPersistenceFactory { filePath in
            SQLiteDatabaseVersionPersistence(filePath: filePath)
        }
        versionUpdater = DefaultTranslationsVersionUpdater(
            persistence: persistence,
            versionPersistenceCreator: versionFactory,
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
            return try await group.collect()
        }
    }

    private func updateInstalledVersion(of translation: Translation) async throws -> Translation {
        try versionUpdater.updateInstalledVersion(for: translation)
    }
}
