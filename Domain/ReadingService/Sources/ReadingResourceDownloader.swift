//
//  ReadingResourceDownloader.swift
//
//
//  Created by Mohamed Afifi on 2023-11-20.
//

import BatchDownloader
import QuranKit

struct ReadingResourceDownloader {
    // MARK: Lifecycle

    init(downloader: DownloadManager, remoteResources: ReadingRemoteResources?) {
        self.downloader = downloader
        self.remoteResources = remoteResources
    }

    // MARK: Internal

    let downloader: DownloadManager
    let remoteResources: ReadingRemoteResources?

    func download(
        _ reading: Reading,
        onProgressChange: @Sendable @escaping (Double) -> Void
    ) async throws {
        // If nil, then it's a local resource
        guard let remoteResource = remoteResources?.resource(for: reading) else {
            return
        }

        let download: DownloadBatchResponse

        // If already downloading, use it (e.g. waking up from background), otherwise download.
        let runningReadings = await runningReadings()
        if let runningReading = runningReadings.first(where: { remoteResource.matches($0) }) {
            download = runningReading
        } else {
            let request = DownloadRequest(url: remoteResource.url, destination: remoteResource.zipFile)
            download = try await downloader.download(DownloadBatchRequest(requests: [request]))
        }

        for try await progress in download.progress {
            onProgressChange(progress.progress)
        }

        try Task.checkCancellation()
    }

    func cancelDownload(exclude reading: Reading) async {
        let execludedResource = remoteResources?.resource(for: reading)
        let runningReadings = await runningReadings()
        for runningReading in runningReadings {
            if let execludedResource, execludedResource.matches(runningReading) {
                continue
            }
            await runningReading.cancel()
        }
    }

    // MARK: Private

    private func runningReadings() async -> [DownloadBatchResponse] {
        let allDownloads = await downloader.getOnGoingDownloads()
        let downloads = allDownloads.filter { isReading($0) }
        return downloads
    }

    private func isReading(_ response: DownloadBatchResponse) -> Bool {
        response.requests.count == 1 &&
            response.requests.contains { Reading.isDownloadDesitnationPath($0.destination) }
    }
}

private extension RemoteResource {
    func matches(_ batch: DownloadBatchResponse) -> Bool {
        if let request = batch.requests.first, batch.requests.count == 1 {
            return matches(request)
        }
        return false
    }

    func matches(_ request: DownloadRequest) -> Bool {
        request.destination == downloadDestination
    }
}
