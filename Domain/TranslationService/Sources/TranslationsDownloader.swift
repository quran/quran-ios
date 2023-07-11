//
//  TranslationsDownloader.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import BatchDownloader
import Foundation
import QuranText

public struct TranslationsDownloader {
    // MARK: Lifecycle

    public init(downloader: DownloadManager) {
        self.downloader = downloader
    }

    // MARK: Public

    public func download(_ translation: Translation) async throws -> DownloadBatchResponse {
        // download the translation
        let download = DownloadRequest(url: translation.fileURL, destination: translation.unprocessedLocalPath)
        let response = try await downloader.download(DownloadBatchRequest(requests: [download]))
        return response
    }

    public func runningTranslationDownloads() async -> [DownloadBatchResponse] {
        let allDownloads = await downloader.getOnGoingDownloads()
        let downloads = allDownloads.filter(\.isTranslation)
        return downloads
    }

    // MARK: Internal

    let downloader: DownloadManager
}

extension Set<DownloadBatchResponse> {
    public nonisolated func firstMatches(_ translation: Translation) -> DownloadBatchResponse? {
        for batch in self {
            if let request = batch.requests.first {
                if translation.matches(request) {
                    return batch
                }
            }
        }
        return nil
    }
}

extension [Translation] {
    public func firstMatches(_ batch: DownloadBatchResponse) -> Translation? {
        guard let request = batch.requests.first else {
            return nil
        }

        return first { $0.matches(request) }
    }
}

private extension Translation {
    func matches(_ request: DownloadRequest) -> Bool {
        request.destination == unprocessedLocalPath
    }
}
