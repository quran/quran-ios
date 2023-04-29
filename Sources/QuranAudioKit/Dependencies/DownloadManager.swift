//
//  DownloadManager.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import BatchDownloader
import Foundation
import PromiseKit

public protocol DownloadManager {
    func getOnGoingDownloads() async -> [DownloadBatchResponse]
    func download(_ batch: DownloadBatchRequest) async throws -> DownloadBatchResponse
}

extension BatchDownloader.DownloadManager: DownloadManager {
}
