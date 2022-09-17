//
//  LocalTranslationsRetriever.swift
//
//
//  Created by Afifi, Mohamed on 10/29/21.
//

import Foundation
import PromiseKit

public struct LocalTranslationsRetriever {
    let persistence: ActiveTranslationsPersistence
    let versionUpdater: TranslationsVersionUpdater

    public init(databasesPath: String) {
        persistence = SQLiteActiveTranslationsPersistence(directory: databasesPath)
        let versionFactory = VersionPersistenceFactory { filePath in
            SQLiteDatabaseVersionPersistence(filePath: filePath)
        }
        versionUpdater = DefaultTranslationsVersionUpdater(
            selectedTranslationsPreferences: DefaultsSelectedTranslationsPreferences(),
            persistence: persistence,
            versionPersistenceCreator: versionFactory,
            unzipper: DefaultTranslationUnzipper()
        )
    }

    public func getLocalTranslations() -> Promise<[Translation]> {
        DispatchQueue.global()
            .async(.promise) {
                try persistence.retrieveAll()
            }
            .then { translations in
                when(fulfilled: translations.map { translation in
                    DispatchQueue.global().async(.promise) {
                        try versionUpdater.updateInstalledVersion(for: translation)
                    }
                })
            }
    }
}
