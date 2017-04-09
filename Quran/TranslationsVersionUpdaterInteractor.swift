//
//  TranslationsVersionUpdaterInteractor.swift
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

import PromiseKit
import Zip

class TranslationsVersionUpdaterInteractor: Interactor {

    private let persistence: ActiveTranslationsPersistence
    private let downloader: DownloadManager
    private let versionPersistenceCreator: AnyCreator<DatabaseVersionPersistence, String>

    init(persistence: ActiveTranslationsPersistence,
         downloader: DownloadManager,
         versionPersistenceCreator: AnyCreator<DatabaseVersionPersistence, String>) {
        self.persistence = persistence
        self.downloader = downloader
        self.versionPersistenceCreator = versionPersistenceCreator
    }

    func execute(_ translations: [Translation]) -> Promise<[TranslationFull]> {
        let update = Promise(value: translations)
            .then(on: .global(), execute: unzipIfNeeded)    // unzip if needed
            .then(on: .global(), execute: updateInstalledVersions) // update versions
        let downloads = downloader.getOnGoingDownloads()
        return when(fulfilled: update, downloads)
            .then(on: .global(), execute: createTranslations)
    }

    private func createTranslations(translations: [Translation], downloadsBatches: [[DownloadNetworkResponse]]) -> [TranslationFull] {
        let downloads = downloadsBatches
            .flatMap { $0 }
            .filter { $0.download.isTranslation }

        let downloadsByFile = downloads.flatGroup { $0.download.destinationPath.stringByDeletingPathExtension }

        return translations.map { translation -> TranslationFull in
            // downloading...
            let responses = translation.possibleFileNames.flatMap {
                downloadsByFile[Files.translationsPathComponent.stringByAppendingPath($0.stringByDeletingPathExtension)]
            }
            if let response = responses.first {
                return TranslationFull(translation: translation, downloadResponse: response)
            }

            // not downloaded
            return TranslationFull(translation: translation, downloadResponse: nil)
        }
    }

    private func updateInstalledVersions(translations: [Translation]) throws -> [Translation] {
        var updatedTranslations: [Translation] = []
        for var translation in translations {

            let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
            let isReachable = fileURL.isReachable
            let previousInstalledVersion = translation.installedVersion

            // installed on the latest version & the db file exists
            if translation.version != translation.installedVersion && isReachable {
                let versionPersistence = versionPersistenceCreator.create(fileURL.absoluteString)
                let version = try versionPersistence.getTextVersion()
                translation.installedVersion = version
            } else if translation.installedVersion != nil && !isReachable {
                translation.installedVersion = nil
            }

            if previousInstalledVersion != translation.installedVersion {
                try persistence.update(translation)
            }
            updatedTranslations.append(translation)
        }
        return updatedTranslations
    }

    private func unzipIfNeeded(translations: [Translation]) throws -> [Translation] {
        for translation in translations {
            // installed on the latest version
            guard translation.version != translation.installedVersion else {
                continue
            }

            /* states:
             Is Zip, zip exists  , db exists
             false,  x           , false     // Not Downloaded
             fasle,  x           , true      // need to check version (might be download/updgrade)
             true,   false       , false     // Not Downloaded
             true,   false       , true      // need to check version (might be download/updgrade)
             true,   true        , false     // Unzip, delete zip, check version
             true,   true        , true      // Unzip, delete zip, check version | Probably upgrade
             */

            // unzip if needed
            let raw = translation.rawFileName
            let isZip = raw.hasSuffix(Files.translationCompressedFileExtension)
            if isZip {
                let zipFile = Files.translationsURL.appendingPathComponent(raw)
                if zipFile.isReachable {

                    // delete the zip in both cases (success or failure)
                    // success: to save space
                    // failure: to redownload it again
                    defer {
                        try? FileManager.default.removeItem(at: zipFile)
                    }
                    try attempt(times: 3) {
                        try Zip.unzipFile(zipFile, destination: Files.translationsURL, overwrite: true, password: nil, progress: nil)
                    }
                }
            }
        }
        return translations
    }
}
