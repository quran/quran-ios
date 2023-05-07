//
//  QuranAudioDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/21/17.
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
import Foundation
import QuranKit

public struct QuranAudioDownloader {
    let downloader: DownloadManager
    let fileListFactory: ReciterAudioFileListRetrievalFactory
    private let fileSystem: FileSystem

    init(downloader: DownloadManager,
         fileListFactory: ReciterAudioFileListRetrievalFactory,
         fileSystem: FileSystem)
    {
        self.downloader = downloader
        self.fileListFactory = fileListFactory
        self.fileSystem = fileSystem
    }

    public init(baseURL: URL, downloader: DownloadManager) {
        self.downloader = downloader
        fileListFactory = DefaultReciterAudioFileListRetrievalFactory(baseURL: baseURL)
        fileSystem = DefaultFileSystem()
    }

    public func downloaded(reciter: Reciter, from start: AyahNumber, to end: AyahNumber) async -> Bool {
        let files = filesForReciter(reciter, from: start, to: end)
        return files.allSatisfy { fileSystem.fileExists(at: FileManager.documentsURL.appendingPathComponent($0.destinationPath)) }
    }

    public func download(from start: AyahNumber, to end: AyahNumber, reciter: Reciter) async throws -> DownloadBatchResponse {
        let retriever = fileListFactory.fileListRetrievalForReciter(reciter)

        // get downloads
        let files = retriever
            .get(for: reciter, from: start, to: end)
            .filter { !FileManager.documentsURL.appendingPathComponent($0.local).isReachable }
            .map { DownloadRequest(url: $0.remote, destinationPath: $0.local) }
        let request = DownloadBatchRequest(requests: files)
        // create downloads
        return try await downloader.download(request)
    }

    public func cancelAllAudioDownloads() async {
        for download in await runningAudioDownloads() {
            await download.cancel()
        }
    }

    public func runningAudioDownloads() async -> [DownloadBatchResponse] {
        let batches = await downloader.getOnGoingDownloads()
        let responses = await batches.asyncFilter { await $0.isAudio }
        return responses
    }

    private func filesForReciter(_ reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [DownloadRequest] {
        let audioFileList = fileListFactory.fileListRetrievalForReciter(reciter)
        return audioFileList.get(for: reciter, from: start, to: end).map {
            DownloadRequest(url: $0.remote, destinationPath: $0.local)
        }
    }
}

extension Set where Element == DownloadBatchResponse {
    public func firstMatches(_ reciter: Reciter) async -> DownloadBatchResponse? {
        for batch in self {
            let download = await batch.requests.first
            if download?.reciterPath == reciter.path {
                return batch
            }
        }
        return nil
    }
}

extension Array where Element == Reciter {
    public func firstMatches(_ batch: DownloadBatchResponse) async -> Reciter? {
        if let download = await batch.requests.first {
            return first { $0.path == download.reciterPath }
        }
        return nil
    }
}

private extension DownloadRequest {
    var reciterPath: String {
        destinationPath.stringByDeletingLastPathComponent
    }
}
