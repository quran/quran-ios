//
//  AyahsAudioDownloader.swift
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
import PromiseKit
import QuranKit

public struct AyahsAudioDownloader {
    let downloader: DownloadManager
    let fileListFactory: ReciterAudioFileListRetrievalFactory
    init(downloader: DownloadManager, fileListFactory: ReciterAudioFileListRetrievalFactory) {
        self.downloader = downloader
        self.fileListFactory = fileListFactory
    }

    public init(baseURL: URL, downloader: DownloadManager) {
        self.downloader = downloader
        fileListFactory = DefaultReciterAudioFileListRetrievalFactory(quran: Quran.madani, baseURL: baseURL)
    }

    public func download(from start: AyahNumber, to end: AyahNumber, reciter: Reciter) -> Promise<DownloadBatchResponse> {
        DispatchQueue.global()
            .async(.guarantee) { () -> DownloadBatchRequest in
                let retriever = self.fileListFactory.fileListRetrievalForReciter(reciter)

                // get downloads
                let files = retriever
                    .get(for: reciter, from: start, to: end)
                    .filter { !FileManager.documentsURL.appendingPathComponent($0.local).isReachable }
                    .map { DownloadRequest(url: $0.remote, destinationPath: $0.local) }
                return DownloadBatchRequest(requests: files)
            }
            .then {
                // create downloads
                self.downloader.download($0)
            }
    }

    public func downloadingAudios(_ reciters: [Reciter]) -> Guarantee<[Reciter: DownloadBatchResponse]> {
        downloader.getOnGoingDownloads()
            .map { self.audioResponses(reciters, downloads: $0) }
    }

    private func audioResponses(_ reciters: [Reciter], downloads: [DownloadBatchResponse]) -> [Reciter: DownloadBatchResponse] {
        var paths: [String: DownloadBatchResponse] = [:]
        for batch in downloads {
            if let download = batch.requests.first, batch.isAudio {
                paths[download.destinationPath.stringByDeletingLastPathComponent] = batch
            }
        }

        var responses: [Reciter: DownloadBatchResponse] = [:]
        for reciter in reciters {
            responses[reciter] = paths[reciter.path]
        }
        return responses
    }
}
