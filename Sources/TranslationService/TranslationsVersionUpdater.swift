//
//  TranslationsVersionUpdater.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import BatchDownloader
import PromiseKit

protocol TranslationsVersionUpdater {
    func updateInstalledVersion(for translation: Translation) throws -> Translation
}

struct VersionPersistenceFactory {
    let create: (String) -> DatabaseVersionPersistence
}

struct DefaultTranslationsVersionUpdater: TranslationsVersionUpdater {
    let selectedTranslationsPreferences: WriteableSelectedTranslationsPreferences
    let persistence: ActiveTranslationsPersistence
    let versionPersistenceCreator: VersionPersistenceFactory
    let unzipper: TranslationUnzipper

    func updateInstalledVersion(for translation: Translation) throws -> Translation {
        try unzipper.unzipIfNeeded(translation) // unzip if needed
        return try updateInstalledVersion(translation) // update versions
    }

    private func updateInstalledVersion(_ translation: Translation) throws -> Translation {
        var translation = translation
        let fileURL = translation.localURL
        let isReachable = fileURL.isReachable
        let previousInstalledVersion = translation.installedVersion

        // installed on the latest version & the db file exists
        if translation.version != translation.installedVersion, isReachable {
            let versionPersistence = versionPersistenceCreator.create(fileURL.absoluteString)
            do {
                let version = try versionPersistence.getTextVersion()
                translation.installedVersion = version
            } catch {
                // if an error occurred while getting the version
                // that means the db file is corrupted.
                translation.installedVersion = nil
            }
        } else if translation.installedVersion != nil, !isReachable {
            translation.installedVersion = nil
        }

        if previousInstalledVersion != translation.installedVersion {
            try persistence.update(translation)

            // remove the translation from selected translations
            if translation.installedVersion == nil {
                var selectedTranslations = selectedTranslationsPreferences.selectedTranslations
                if let index = selectedTranslations.firstIndex(of: translation.id) {
                    selectedTranslations.remove(at: index)
                    selectedTranslationsPreferences.selectedTranslations = selectedTranslations
                }
            }
        }
        return translation
    }
}

private extension DownloadRequest {
    var isTranslation: Bool {
        destinationPath.hasPrefix(Translation.translationsPathComponent)
    }
}

private extension DownloadBatchResponse {
    var isTranslation: Bool {
        requests.count == 1 && requests.contains(where: \.isTranslation)
    }
}
