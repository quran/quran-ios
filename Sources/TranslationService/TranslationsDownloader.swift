//
//  TranslationsDownloader.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import BatchDownloader
import Foundation

public struct TranslationsDownloader {
    let downloader: DownloadManager
    public init(downloader: DownloadManager) {
        self.downloader = downloader
    }

    public func download(_ translation: Translation) async throws -> DownloadBatchResponse {
        // download the translation
        let destinationPath = Translation.translationsPathComponent.stringByAppendingPath(translation.rawFileName)
        let download = DownloadRequest(url: translation.fileURL, destinationPath: destinationPath)
        let response = try await downloader.download(DownloadBatchRequest(requests: [download]))
        return response
    }

    public func runningTranslationDownloads() async -> [DownloadBatchResponse] {
        let allDownloads = await downloader.getOnGoingDownloads()
        let downloads = await allDownloads.asyncFilter { await $0.isTranslation }
        return downloads
    }
}

extension Set where Element == DownloadBatchResponse {
    public func firstMatches(_ translation: Translation) async -> DownloadBatchResponse? {
        for batch in self {
            if let request = await batch.requests.first {
                if translation.matches(request) {
                    return batch
                }
            }
        }
        return nil
    }
}

extension Array where Element == Translation {
    public func firstMatches(_ batch: DownloadBatchResponse) async -> Translation? {
        guard let request = await batch.requests.first else {
            return nil
        }

        return first { $0.matches(request) }
    }
}

private extension Translation {
    func matches(_ request: DownloadRequest) -> Bool {
        possibleFileNames.map { Translation.translationsPathComponent.stringByAppendingPath($0.stringByDeletingPathExtension) }
            .contains(request.destinationPath.stringByDeletingPathExtension)
    }
}
