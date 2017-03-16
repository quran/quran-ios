//
//  TranslationsVersionUpdaterInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
        return Promise(value: translations)
            .then(on: .global(), execute: unzipIfNeeded)    // unzip if needed
            .then(on: .translations, execute: updateInstalledVersions) // update versions
            .then(on: .global(), execute: createTranslations)
    }

    private func createTranslations(translations: [Translation]) -> [TranslationFull] {
        let downloads = downloader.getOnGoingDownloads()
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

    private func onGoingDownloads() -> Promise<[DownloadNetworkResponse]> {
        return Promise(value: downloader.getOnGoingDownloads()
            .flatMap { $0 }
            .filter { $0.download.isTranslation })
    }

    private func updateInstalledVersions(translations: [Translation]) throws -> [Translation] {
        var updatedTranslations: [Translation] = []
        for var translation in translations {

            let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
            // installed on the latest version & the db file exists
            if translation.version != translation.installedVersion && fileURL.isReachable {

                let versionPersistence = versionPersistenceCreator.create(parameters: fileURL.absoluteString)
                let version = try versionPersistence.getTextVersion()
                translation.installedVersion = version
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
                        let _ = try? FileManager.default.removeItem(at: zipFile)
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
