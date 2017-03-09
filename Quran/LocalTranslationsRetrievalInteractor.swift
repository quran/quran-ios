//
//  LocalTranslationsRetrievalInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/7/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

class LocalTranslationsRetrievalInteractor: Interactor {

    private let persistence: ActiveTranslationsPersistence
    private let downloader: DownloadManager

    init(persistence: ActiveTranslationsPersistence, downloader: DownloadManager) {
        self.persistence = persistence
        self.downloader = downloader
    }

    func execute(_ input: Void) -> Promise<[TranslationFull]> {

        let local = Queue.translations.queue.promise { [weak self] (Void) -> [Translation] in
            guard let `self` = self else { return [] }
            return try self.persistence.retrieveAll()
        }

        return local
            .then { [weak self] translations -> ([Translation], [DownloadNetworkResponse]) in
                let batches = self?.downloader.getOnGoingDownloads()
                let downloads = batches?.flatMap { $0.filter { $0.download.isTranslation } }
                return (translations, downloads ?? [])
            }.then(on: .background) { (translations, downloads) -> [TranslationFull] in
                return TranslationFull.createTransltionsFull(translations, downloads: downloads)
        }
    }
}

extension TranslationFull {
    static func createTransltionsFull(_ translations: [Translation], downloads: [DownloadNetworkResponse]) -> [TranslationFull] {
        let downloadsByFile = downloads.flatGroup { $0.download.destinationPath.stringByDeletingPathExtension }

        let translationsFull = translations.map { translation -> TranslationFull in
            // check if file downloaded already
            let possibleFiles = translation.possibleFileNames
            if possibleFiles.contains(where: { fileName in
                (try? Files.translationsURL.appendingPathComponent(fileName).checkResourceIsReachable()) ?? false }) {
                return TranslationFull(translation: translation, downloaded: true, downloadResponse: nil)
            }

            // downloading...?
            let responses = possibleFiles.flatMap {
                downloadsByFile[Files.translationsPathComponent.stringByAppendingPath($0.stringByDeletingPathExtension)]
            }
            if let response = responses.first {
                return TranslationFull(translation: translation, downloaded: false, downloadResponse: response)
            }

            // not downloaded
            return TranslationFull(translation: translation, downloaded: false, downloadResponse: nil)
        }
        return translationsFull
    }
}
