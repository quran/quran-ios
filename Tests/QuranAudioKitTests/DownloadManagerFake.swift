//
//  DownloadManagerFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import BatchDownloader
import Foundation
import PromiseKit
import QuranAudioKit

class DownloadManagerFake: QuranAudioKit.DownloadManager {
    var downloads: [DownloadBatchResponse] = []
    let queue = DispatchQueue(label: "DownloadManagerFake")
    var responses: [DownloadBatchRequest: DownloadBatchResponse] = [:]

    enum DownloadError: Error {
        case notFound
    }

    func getOnGoingDownloads() async -> [DownloadBatchResponse] {
        await Task {
            self.downloads
        }.value
    }

    func download(_ batch: DownloadBatchRequest) async throws -> DownloadBatchResponse {
        try await Task {
            if let response = self.responses[batch] {
                return response
            }
            throw DownloadError.notFound
        }.value
    }
}
