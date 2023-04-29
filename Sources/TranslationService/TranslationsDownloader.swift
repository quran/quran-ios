//
//  TranslationsDownloader.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import BatchDownloader
import Foundation
import PromiseKit

public struct TranslationsDownloader {
    let downloader: DownloadManager
    public init(downloader: DownloadManager) {
        self.downloader = downloader
    }

    public func download(_ translation: Translation) -> Promise<DownloadBatchResponse> {
        // download the translation
        let destinationPath = Translation.translationsPathComponent.stringByAppendingPath(translation.rawFileName)
        let download = DownloadRequest(url: translation.fileURL, destinationPath: destinationPath)
        return DispatchQueue.global().asyncPromise {
            try await downloader.download(DownloadBatchRequest(requests: [download]))
        }
    }

    public func downloadingTranslations(_ translations: [Translation]) -> Guarantee<[Translation: DownloadBatchResponse]> {
        DispatchQueue.global().asyncGuarantee {
            let downloads = await self.downloader.getOnGoingDownloads()
            return self.translationResponses(translations, downloadsBatches: downloads)
        }
    }

    private func translationResponses(_ translations: [Translation],
                                      downloadsBatches: [DownloadBatchResponse]) -> [Translation: DownloadBatchResponse]
    {
        let downloads = downloadsBatches.filter(\.isTranslation)

        let downloadsByFile = downloads.flatGroup { $0.requests.first?.destinationPath.stringByDeletingPathExtension ?? "_" }

        var translationResponses: [Translation: DownloadBatchResponse] = [:]
        for translation in translations {
            // downloading...
            let responses = translation.possibleFileNames.compactMap {
                downloadsByFile[Translation.translationsPathComponent.stringByAppendingPath($0.stringByDeletingPathExtension)]
            }
            if let response = responses.first {
                translationResponses[translation] = response
            }
        }
        return translationResponses
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
