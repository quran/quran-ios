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
import QuranText
import SystemDependencies
import TranslationPersistence
import VerseTextPersistence

typealias VersionPersistenceFactory = (Translation) -> DatabaseVersionPersistence

struct TranslationsVersionUpdater {
    // MARK: Internal

    let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    let persistence: ActiveTranslationsPersistence
    let versionPersistenceFactory: VersionPersistenceFactory
    let unzipper: TranslationUnzipper
    let fileSystem: FileSystem

    func updateInstalledVersion(for translation: Translation) async throws -> Translation {
        try unzipper.unzipIfNeeded(translation) // unzip if needed
        return try await updateInstalledVersion(translation) // update versions
    }

    // MARK: Private

    private func updateInstalledVersion(_ translation: Translation) async throws -> Translation {
        var translation = translation
        let isReachable = fileSystem.fileExists(at: translation.localURL)
        let previousInstalledVersion = translation.installedVersion

        // installed on the latest version & the db file exists
        if translation.version != translation.installedVersion, isReachable {
            do {
                let versionPersistence = versionPersistenceFactory(translation)
                let version = try await versionPersistence.getTextVersion()
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
            try await persistence.update(translation)

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

extension DownloadRequest {
    var isTranslation: Bool {
        Translation.isLocalTranslationURL(destinationURL)
    }
}

extension DownloadBatchResponse {
    nonisolated var isTranslation: Bool {
        requests.count == 1 && requests.contains(where: \.isTranslation)
    }
}
